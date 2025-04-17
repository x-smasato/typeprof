module TypeProf::LSP
  require 'prism'

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
      filtered_diagnostics = TypeProf::DiagnosticFilter.new(
        ignored_lines,
        ignored_blocks,
        @core_options[:show_errors]
      ).call(diagnostics)

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

        # Prismでパースする
        result = Prism.parse(content)

        if result.failure?
          if @core_options[:show_errors]
            warn "Error: Failed to parse content for #{path}. Content may be invalid."
          end
          return [ignored_lines, ignored_blocks]
        end

        # 直接各行を処理するアプローチに変更
        lines = content.lines

        # コメントを行ごとに整理
        line_comments = {}
        result.comments.each do |comment|
          line = comment.location.start_line
          line_comments[line] ||= []
          line_comments[line] << comment
        end

        # コードがある行を抽出
        code_lines = Set.new
        collect_code_lines(result.value, code_lines)

        current_block_start = nil

        # 各行を1行ずつ確認（1-indexed）
        1.upto(lines.size) do |line_num|
          comments = line_comments[line_num] || []

          # この行のすべてのコメントを連結したテキスト (行末コメントも含む)
          comment_text = comments.map { |c| c.location.slice }.join(' ')
          line_text = lines[line_num - 1] || ''

          has_code = code_lines.include?(line_num)
          has_disable = comment_text.match?(/\s*#\s*typeprof:disable\b/)
          has_enable = comment_text.match?(/\s*#\s*typeprof:enable\b/)

          # 行全体の内容を調べて、"typeprof:disable"が含まれているか確認 (行末コメント対応)
          if !has_disable
            if line_text.match?(/.*#.*typeprof:disable\b/)
              has_disable = true
              warn "Debug: Found inline disable comment on line #{line_num}" if @core_options[:show_errors]
            elsif line_text.include?('# typeprof:disable')
              has_disable = true
              warn "Debug: Found exact inline disable comment on line #{line_num}" if @core_options[:show_errors]
            end
          end

          if has_disable
            if has_code
              # コードと同じ行にdisableコメントがある場合は、その行を無視
              ignored_lines.add(line_num)
              warn "Debug: Adding ignored line #{line_num} with code and disable comment" if @core_options[:show_errors]
            elsif !current_block_start
              # コードがなく、ブロック開始されていない場合は新しいブロック開始
              current_block_start = line_num
              warn "Debug: Starting block at line #{line_num}" if @core_options[:show_errors]
            end
          elsif has_enable && current_block_start
            # enableコメントがある場合は範囲指定モードを終了
            ignored_blocks << [current_block_start, line_num]
            warn "Debug: Adding block from #{current_block_start} to #{line_num}" if @core_options[:show_errors]
            current_block_start = nil
          end
        end

        # ファイル末尾までブロックが続いていた場合
        if current_block_start
          ignored_blocks << [current_block_start, Float::INFINITY]
          warn "Debug: Adding end-of-file block from line #{current_block_start}" if @core_options[:show_errors]
        end

        # ブロック範囲内の行を処理
        ignored_blocks.each do |start_line, end_line|
          next_line = start_line + 1 # disableコメントの次の行から開始
          end_line = lines.size if end_line == Float::INFINITY

          # start_line と end_line の間の行を無視
          (next_line...end_line).each do |line_num|
            # ブロック内のすべての行を無視対象に追加（コードかどうかに関わらず）
            ignored_lines.add(line_num)
            warn "Debug: Adding block line #{line_num} to ignored lines" if @core_options[:show_errors]
          end
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

    # ノードから行番号を収集するヘルパーメソッド
    def collect_code_lines(node, lines)
      return unless node.is_a?(Prism::Node)

      # 現在のノードの行番号を追加
      if node.location
        start_line = node.location.start_line
        end_line = node.location.end_line
        (start_line..end_line).each { |line| lines.add(line) }
      end

      # 子ノードを再帰的に処理
      node.child_nodes.each { |child| collect_code_lines(child, lines) if child }
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
