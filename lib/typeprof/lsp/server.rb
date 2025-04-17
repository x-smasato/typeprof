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
      return unless target_path?(path)

      warn "\nDebug: Publishing diagnostics for #{path} (URI: #{uri})" if @core_options[:show_errors]

      all_diagnostics = []
      each_core(path) do |core|
        core.diagnostics(path) { |diag| all_diagnostics << diag }
      end

      # 無視する行とブロックを収集
      ignored_lines, ignored_blocks = collect_ignored_lines(path)

      if @core_options[:show_errors]
        warn "Debug: Collected ignored lines for #{path}: #{ignored_lines.to_a.sort}"
        warn "Debug: Collected ignored blocks for #{path}: #{ignored_blocks.inspect}"
        warn "Debug: Original diagnostics count for #{path}: #{all_diagnostics.size}"
      end

      # DiagnosticFilter を使ってフィルタリング
      filtered_diagnostics = TypeProf::DiagnosticFilter.new(
        ignored_lines,
        ignored_blocks,
        @core_options[:show_errors]
      ).call(all_diagnostics)

      warn "Debug: Filtered diagnostics count for #{path}: #{filtered_diagnostics.size}" if @core_options[:show_errors]

      diagnostics = filtered_diagnostics.map do |diag|
        {
          range: diag.code_range.to_lsp_range,
          severity: lsp_severity(@diagnostic_severity),
          source: 'TypeProf',
          message: diag.msg
        }
      end

      send_notification('textDocument/publishDiagnostics', uri: uri, diagnostics: diagnostics)
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
        # .rbe.rb ファイルの場合、元の .rb ファイルを読む（CLIと同じ）
        original_path = path.end_with?('.rbe.rb') ? path.sub(/\.rbe\.rb$/, '.rb') : path
        uri = path_to_uri(original_path)
        # open_texts のキーは uri なので、まずそちらを優先して参照
        content = @open_texts[uri]&.string || File.read(original_path)

        result = Prism.parse(content)
        return [ignored_lines, ignored_blocks] unless result.success? # パース失敗時は無視

        lines = content.lines

        line_comments = {}
        result.comments.each do |comment|
          line = comment.location.start_line
          line_comments[line] ||= []
          line_comments[line] << comment
        end

        code_lines = Set.new
        collect_code_lines(result.value, code_lines)

        current_block_start = nil

        1.upto(lines.size) do |line_num|
          comments = line_comments[line_num] || []
          comment_text = comments.map { |c| c.location.slice }.join(' ')
          line_text = lines[line_num - 1] || ''
          has_code = code_lines.include?(line_num)
          has_disable = comment_text.match?(/\s*#\s*typeprof:disable\b/) || line_text.match?(/\s*#\s*typeprof:disable\b/)
          has_enable = comment_text.match?(/\s*#\s*typeprof:enable\b/) || line_text.match?(/\s*#\s*typeprof:enable\b/)

          if current_block_start
            if has_enable
              ignored_lines.add(line_num)
              ignored_blocks << [current_block_start, line_num]
              current_block_start = nil
            else
              ignored_lines.add(line_num)
            end
          elsif has_disable
            if has_code && !line_text.strip.start_with?('#')
              ignored_lines.add(line_num)
            else
              ignored_lines.add(line_num)
              current_block_start = line_num
            end
          end
        end

        if current_block_start
          ignored_blocks << [current_block_start, Float::INFINITY]
          (current_block_start + 1).upto(lines.size) do |line_num|
            ignored_lines.add(line_num)
          end
        end
      rescue Errno::ENOENT
        # ファイルが存在しない場合は無視リストは空
      rescue StandardError => e
        if @core_options[:show_errors]
          warn "Warning: Failed to collect ignored lines from #{original_path}: #{e.message}"
        end
      end

      [ignored_lines, ignored_blocks]
    end

    def collect_code_lines(node, lines)
      return unless node.is_a?(Prism::Node)

      if node.location
        start_line = node.location.start_line
        end_line = node.location.end_line
        (start_line..end_line).each { |line| lines.add(line) }
      end

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
        # typeprof:disable
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
