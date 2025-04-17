module TypeProf::LSP
  require 'ripper'

  module ErrorCodes
    ParseError = -32_700
    InvalidRequest = -32_600
    MethodNotFound = -32_601
    InvalidParams = -32_602
    InternalError = -32_603
  end

  class Server
    def self.start_stdio(core_options)
      $stdin.binmode
      $stdout.binmode
      reader = Reader.new($stdin)
      writer = Writer.new($stdout)
      # pipe all builtin print output to stderr to avoid conflicting with lsp
      $stdout = $stderr
      new(core_options, reader, writer).run
    end

    def self.start_socket(core_options)
      Socket.tcp_server_sockets('localhost', nil) do |servs|
        serv = servs[0].local_address
        $stdout << JSON.generate({
                                   host: serv.ip_address,
                                   port: serv.ip_port,
                                   pid: $$
                                 })
        $stdout.flush

        $stdout = $stderr

        Socket.accept_loop(servs) do |sock|
          sock.set_encoding('UTF-8')
          begin
            reader = Reader.new(sock)
            writer = Writer.new(sock)
            new(core_options, reader, writer).run
          ensure
            sock.close
          end
          exit
        end
      end
    end

    def initialize(core_options, reader, writer, url_schema: nil, publish_all_diagnostics: false)
      @core_options = core_options
      @cores = {}
      @reader = reader
      @writer = writer
      @request_id = 0
      @running_requests_from_client = {}
      @running_requests_from_server = {}
      @open_texts = {}
      @exit = false
      @signature_enabled = true
      @url_schema = url_schema || (File::ALT_SEPARATOR != '\\' ? 'file://' : 'file:///')
      @publish_all_diagnostics = publish_all_diagnostics # TODO: implement more dedicated publish feature
      @diagnostic_severity = :error
    end

    attr_reader :open_texts
    attr_accessor :signature_enabled

    # : (String) -> String
    def path_to_uri(path)
      @url_schema + File.expand_path(path)
    end

    def uri_to_path(url)
      url.delete_prefix(@url_schema)
    end

    # : (Array[String]) -> void
    def add_workspaces(folders)
      folders.each do |path|
        conf_path = ['.json', '.jsonc'].map do |ext|
          File.join(path, 'typeprof.conf' + ext)
        end.find do |path|
          File.readable?(path)
        end
        unless conf_path
          puts "typeprof.conf.json is not found in #{path}"
          next
        end
        conf = TypeProf::LSP.load_json_with_comments(conf_path, symbolize_names: true)
        next unless conf

        rbs_dir = File.expand_path(conf[:rbs_dir] || File.expand_path('sig', path))
        @rbs_dir = rbs_dir
        if conf[:typeprof_version] == 'experimental'
          if conf[:diagnostic_severity]
            severity = conf[:diagnostic_severity].to_sym
            case severity
            when :error, :warning, :info, :hint
              @diagnostic_severity = severity
            else
              puts "unknown severity: #{severity}"
            end
          end
          conf[:analysis_unit_dirs].each do |dir|
            dir = File.expand_path(dir, path)
            core = @cores[dir] = TypeProf::Core::Service.new(@core_options)
            core.add_workspace(dir, @rbs_dir)
          end
        else
          puts "Unknown typeprof_version: #{conf[:typeprof_version]}"
        end
      end
    end

    # : (String) -> bool
    def target_path?(path)
      return true if @rbs_dir && path.start_with?(@rbs_dir)

      @cores.each do |folder, _|
        return true if path.start_with?(folder)
      end
      false
    end

    def each_core(path)
      @cores.each do |folder, core|
        yield core if path.start_with?(folder) || @rbs_dir && path.start_with?(@rbs_dir)
      end
    end

    def aggregate_each_core(path)
      ret = []
      each_core(path) do |core|
        r = yield(core)
        ret.concat(r) if r
      end
      ret
    end

    def update_file(path, text)
      each_core(path) do |core|
        core.update_file(path, text)
      end
    end

    def definitions(path, pos)
      aggregate_each_core(path) do |core|
        core.definitions(path, pos)
      end
    end

    def type_definitions(path, pos)
      aggregate_each_core(path) do |core|
        core.type_definitions(path, pos)
      end
    end

    def references(path, pos)
      aggregate_each_core(path) do |core|
        core.references(path, pos)
      end
    end

    def hover(path, pos)
      ret = []
      each_core(path) do |core|
        ret << core.hover(path, pos)
      end
      ret.compact.first # TODO
    end

    def code_lens(path, &blk)
      each_core(path) do |core|
        core.code_lens(path, &blk)
      end
    end

    def completion(path, trigger, pos, &blk)
      each_core(path) do |core|
        core.completion(path, trigger, pos, &blk)
      end
    end

    def rename(path, pos)
      aggregate_each_core(path) do |core|
        core.rename(path, pos)
      end
    end

    def run
      @reader.read do |json|
        if json[:method]
          # request or notification
          msg_class = Message.find(json[:method])
          if msg_class
            msg = msg_class.new(self, json)
            @running_requests_from_client[json[:id]] = msg if json[:id]
            msg.run
          end
        else
          # response
          callback = @running_requests_from_server.delete(json[:id])
          callback&.call(json[:params], json[:error])
        end
        break if @exit
      end
    end

    def send_response(**msg)
      @running_requests_from_client.delete(msg[:id])
      @writer.write(**msg)
    end

    def send_notification(method, **params)
      @writer.write(method: method, params: params)
    end

    def send_request(method, **params, &blk)
      id = @request_id += 1
      @running_requests_from_server[id] = blk
      @writer.write(id: id, method: method, params: params)
    end

    def cancel_request(id)
      req = @running_requests_from_client[id]
      req.cancel if req.respond_to?(:cancel)
    end

    def exit
      @exit = true
    end

    def publish_diagnostics(uri)
      text = @open_texts[uri]
      return unless text

      path = uri_to_path(uri)

      warn "\nDebug: Publishing diagnostics for #{path} (URI: #{uri})" if @core_options[:show_errors]

      diagnostics = []

      # 無視する行とブロックを収集
      ignored_lines, ignored_blocks = collect_ignored_lines(path)

      if @core_options[:show_errors]
        warn "Debug: Collected ignored lines for #{path}: #{ignored_lines.to_a.sort}"
        warn "Debug: Collected ignored blocks for #{path}: #{ignored_blocks.inspect}"
      end

      each_core(path) do |core|
        core.diagnostics(path) do |diag|
          if @core_options[:show_errors]
            warn "Debug: Found diagnostic: #{diag.code_range}: #{diag.msg} (line: #{diag.code_range.first.lineno})"
          end
          diagnostics << diag
        end
      end

      # DiagnosticFilterを使用して診断をフィルタリング
      filtered_diagnostics = TypeProf::DiagnosticFilter.new(ignored_lines, ignored_blocks).call(diagnostics)

      if @core_options[:show_errors]
        warn "Debug: Total diagnostics: #{diagnostics.size}, Filtered: #{diagnostics.size - filtered_diagnostics.size}"
        filtered_diagnostics.each do |diag|
          warn "Debug: Remaining diagnostic after filtering: #{diag.code_range}: #{diag.msg}"
        end
      end

      # LSP形式に変換
      lsp_diagnostics = filtered_diagnostics.map do |diag|
        lsp_range = diag.code_range.to_lsp_range
        warn "Debug: Converting to LSP range: #{lsp_range.inspect}" if @core_options[:show_errors]

        {
          range: lsp_range,
          severity: lsp_severity(@diagnostic_severity),
          message: diag.msg,
          source: 'TypeProf'
        }
      end

      warn "Debug: Sending #{lsp_diagnostics.size} diagnostics to editor" if @core_options[:show_errors]

      send_notification(
        'textDocument/publishDiagnostics',
        uri: uri,
        diagnostics: lsp_diagnostics
      )
    end

    private

    def lsp_severity(severity)
      case severity
      when :error
        1   # Error
      when :warning
        2   # Warning
      when :info
        3   # Information
      when :hint
        4   # Hint
      else
        1   # デフォルトはError
      end
    end

    def collect_ignored_lines(path)
      ignored_lines = Set.new
      ignored_blocks = []

      begin
        uri = path_to_uri(path)
        text_obj = @open_texts[uri]

        if text_obj.nil?
          warn "Debug: No content found for #{path} (uri: #{uri})" if @core_options[:show_errors]
          return [ignored_lines, ignored_blocks]
        end

        # Text オブジェクトから文字列を取得
        content = text_obj.string

        if @core_options[:show_errors]
          warn "Debug: Processing content for #{path}, size: #{content.size}"
          warn "Debug: Content first 100 chars: #{content[0..100]}"
        end

        # Ripperの結果をより詳細に解析
        tokens = Ripper.lex(content)

        if tokens.nil? || tokens.empty?
          if @core_options[:show_errors]
            warn "Error: Failed to lex content for #{path}. Content may be invalid or empty."
          end
          return [ignored_lines, ignored_blocks]
        end

        # トークンを行ごとにマップする
        line_tokens = {}
        tokens.each do |(pos, type, token)|
          line = pos[0]
          line_tokens[line] ||= { tokens: [], text: '', has_code: false, has_comment: false }
          line_tokens[line][:tokens] << [type, token, pos]
          line_tokens[line][:text] += token
          line_tokens[line][:has_code] = true if type != :on_comment
          line_tokens[line][:has_comment] = true if type == :on_comment
        end

        # 各行でtypeprof:disableコメントを探す
        current_block_start = nil

        line_tokens.each do |line, info|
          # コメントを探す
          disable_comment = nil
          enable_comment = nil

          info[:tokens].each do |(type, token, _pos)|
            if type == :on_comment
              if token.match?(/\s*#\s*typeprof:disable\b/)
                disable_comment = token
                warn "Debug: Found disable comment on line #{line + 1}: #{token}" if @core_options[:show_errors]
              elsif token.match?(/\s*#\s*typeprof:enable\b/)
                enable_comment = token
                warn "Debug: Found enable comment on line #{line + 1}: #{token}" if @core_options[:show_errors]
              end
            end
          end

          # 行に「typeprof:disable」コメントがあるか
          if disable_comment
            if info[:has_code] && info[:tokens].any? { |type, _, _| type != :on_comment }
              # コードと同じ行にdisableコメントがある場合（行末コメント）
              # LSPは0-indexed、DiagnosticFilterは1-indexedを期待
              ignored_lines.add(line + 1)
              warn "Debug: Adding ignored line #{line + 1} with code and disable comment" if @core_options[:show_errors]
            elsif !current_block_start
              # コードがなく、ブロック開始されていない場合は新しいブロック開始
              current_block_start = line

              warn "Debug: Starting block at line #{line + 1}" if @core_options[:show_errors]
            end
          end

          # 行に「typeprof:enable」コメントがあるか
          next unless enable_comment && current_block_start

          # enableコメントがある場合は範囲指定モードを終了
          # CLIとの整合性を保つため、current_block_startそのままで処理する
          ignored_blocks << [current_block_start + 1, line]
          warn "Debug: Adding block from #{current_block_start + 1} to #{line}" if @core_options[:show_errors]
          current_block_start = nil
        end

        # ファイル末尾までブロックが続いていた場合
        if current_block_start
          ignored_blocks << [current_block_start + 1, Float::INFINITY]
          warn "Debug: Adding end-of-file block from line #{current_block_start + 1}" if @core_options[:show_errors]
        end

        if @core_options[:show_errors]
          warn "Debug: Final ignored lines for #{path}: #{ignored_lines.to_a.sort.join(', ')}"
          warn "Debug: Final ignored blocks for #{path}: #{ignored_blocks.inspect}"
        end

        [ignored_lines, ignored_blocks]
      rescue StandardError => e
        warn "Warning: Failed to collect ignored lines from #{path}: #{e.message}" if @core_options[:show_errors]
        warn e.backtrace.join("\n") if @core_options[:show_errors]
        [Set.new, []]
      end
    end
  end

  class Reader
    class ProtocolError < StandardError
    end

    def initialize(io)
      @io = io
    end

    def read
      while line = @io.gets
        line2 = @io.gets
        raise ProtocolError, 'LSP broken header' unless line =~ /\AContent-length: (\d+)\r\n\z/i && line2 == "\r\n"

        len = ::Regexp.last_match(1).to_i
        json = JSON.parse(@io.read(len), symbolize_names: true)
        yield json

      end
    end
  end

  class Writer
    def initialize(io)
      @io = io
      @mutex = Mutex.new
    end

    def write(**json)
      json = JSON.generate(json.merge(jsonrpc: '2.0'))
      @mutex.synchronize do
        @io << "Content-Length: #{json.bytesize}\r\n\r\n" << json
        @io.flush
      end
    end
  end
end
