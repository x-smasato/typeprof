module TypeProf::CLI
  class CLI
    def initialize(argv)
      opt = OptionParser.new

      opt.banner = "Usage: #{ opt.program_name } [options] files_or_dirs..."

      core_options = {}
      lsp_options = {}
      cli_options = {}

      output = nil
      rbs_collection_path = nil

      opt.separator ""
      opt.separator "Options:"
      opt.on("-o OUTFILE", "Output to OUTFILE instead of stdout") {|v| output = v }
      opt.on("-q", "--quiet", "Quiet mode") do
        core_options[:display_indicator] = false
      end
      opt.on("-v", "--verbose", "Verbose mode") do
        core_options[:show_errors] = true
      end
      opt.on("--version", "Display typeprof version") { cli_options[:display_version] = true }
      opt.on("--collection PATH", "File path of collection configuration") { |v| rbs_collection_path = v }
      opt.on("--no-collection", "Ignore collection configuration") { rbs_collection_path = :no }
      opt.on("--lsp", "LSP server mode") do |v|
        core_options[:display_indicator] = false
        cli_options[:lsp] = true
      end

      opt.separator ""
      opt.separator "Analysis output options:"
      opt.on("--[no-]show-typeprof-version", "Display TypeProf version in a header") {|v| core_options[:output_typeprof_version] = v }
      opt.on("--[no-]show-errors", "Display possible errors found during the analysis") {|v| core_options[:output_diagnostics] = v }
      opt.on("--[no-]show-parameter-names", "Display parameter names for methods") {|v| core_options[:output_parameter_names] = v }
      opt.on("--[no-]show-source-locations", "Display definition source locations for methods") {|v| core_options[:output_source_locations] = v }

      opt.separator ""
      opt.separator "Advanced options:"
      opt.on("--[no-]stackprof MODE", /\Acpu|wall|object\z/, "Enable stackprof (for debugging purpose)") {|v| cli_options[:stackprof] = v.to_sym }

      opt.separator ""
      opt.separator "LSP options:"
      opt.on("--port PORT", Integer, "Specify a port number to listen for requests on") {|v| lsp_options[:port] = v }
      opt.on("--stdio", "Use stdio for LSP transport") {|v| lsp_options[:stdio] = v }

      opt.parse!(argv)

      if !cli_options[:lsp] && !lsp_options.empty?
        raise OptionParser::InvalidOption.new("lsp options with non-lsp mode")
      end

      @core_options = {
        rbs_collection: setup_rbs_collection(rbs_collection_path),
        display_indicator: $stderr.tty?,
        output_typeprof_version: true,
        output_errors: false,
        output_parameter_names: false,
        output_source_locations: false,
      }.merge(core_options)

      @lsp_options = {
        port: 0,
        stdio: false,
      }.merge(lsp_options)

      @cli_options = {
        argv:,
        output: output ? open(output, "w") : $stdout.dup,
        display_version: false,
        stackprof: nil,
        lsp: false,
      }.merge(cli_options)

    rescue OptionParser::InvalidOption, OptionParser::MissingArgument
      puts $!
      exit 1
    end

    def setup_rbs_collection(path)
      return nil if path == :no

      unless path
        path = RBS::Collection::Config::PATH.exist? ? RBS::Collection::Config::PATH.to_s : nil
        return nil unless path
      end

      if !File.readable?(path)
        raise OptionParser::InvalidOption.new("file not found: #{ path }")
      end

      lock_path = RBS::Collection::Config.to_lockfile_path(Pathname(path))
      if !File.readable?(lock_path)
        raise OptionParser::InvalidOption.new("file not found: #{ lock_path.to_s }; please run 'rbs collection install")
      end

      RBS::Collection::Config::Lockfile.from_lockfile(lockfile_path: lock_path, data: YAML.load_file(lock_path))
    end

    attr_reader :core_options, :lsp_options, :cli_options

    def run

      if @cli_options[:lsp]
        run_lsp
      else
        run_cli
      end
    end

    def run_lsp
      if @lsp_options[:stdio]
        TypeProf::LSP::Server.start_stdio(@core_options)
      else
        TypeProf::LSP::Server.start_socket(@core_options)
      end
    rescue Exception
      puts $!.detailed_message(highlight: false).gsub(/^/, "---")
      raise
    end

    def collect_ignored_lines(path)
      ignored_lines = Set.new
      ignored_blocks = []

      begin
        original_path = path.end_with?('.rbe.rb') ? path.sub(/\.rbe\.rb$/, '.rb') : path
        content = File.read(original_path)

        result = Prism.parse(content)

        lines = content.lines

        # コメントを行ごとに整理
        line_comments = {}
        result.comments.each do |comment|
          line = comment.location.start_line
          line_comments[line] ||= []
          line_comments[line] << comment
        end

        code_lines = Set.new
        collect_code_lines(result.value, code_lines)

        current_block_start = nil

        # 各行を1行ずつ確認（1-indexed）
        1.upto(lines.size) do |line_num|
          comments = line_comments[line_num] || []
          comment_text = comments.map { |c| c.location.slice }.join(' ')
          line_text = lines[line_num - 1] || ''
          has_code = code_lines.include?(line_num)
          has_disable = comment_text.match?(/\s*#\s*typeprof:disable\b/) || line_text.match?(/\s*#\s*typeprof:disable\b/)
          has_enable = comment_text.match?(/\s*#\s*typeprof:enable\b/) || line_text.match?(/\s*#\s*typeprof:enable\b/)

          if current_block_start
            # ブロック内にいる場合
            if has_enable
              # enable コメントが見つかったらブロック終了
              ignored_lines.add(line_num) # enable 行も無視
              ignored_blocks << [current_block_start, line_num]
              current_block_start = nil
            else
              # ブロック内で enable 以外なら無視
              ignored_lines.add(line_num)
            end
          else
            if has_disable
              if has_code && !line_text.strip.start_with?('#') # コードがあり、行頭コメントではない場合 (インラインdisable)
                # コードと同じ行にある disable はその行だけ無視 (ブロック開始しない)
                ignored_lines.add(line_num)
              else
                # コードがない行、または行頭コメントの disable はブロック開始
                ignored_lines.add(line_num) # disable 行も無視
                current_block_start = line_num
              end
            end
            # ブロック外で disable も enable もない行は 何もしない (無視しない)
          end
        end

        # ファイル末尾までブロックが続いていた場合
        if current_block_start
          ignored_blocks << [current_block_start, Float::INFINITY]
          # ファイル末尾までの行を無視対象に追加
          (current_block_start + 1).upto(lines.size) do |line_num|
            ignored_lines.add(line_num)
          end
        end
      rescue StandardError => e
        if @core_options[:output_diagnostics]
          warn "Warning: Failed to collect ignored lines from #{original_path}: #{e.message}"
        end
      end

      [ignored_lines, ignored_blocks]
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

    def run_cli
      core = TypeProf::Core::Service.new(@core_options)

      puts "typeprof #{ TypeProf::VERSION }" if @cli_options[:display_version]

      files = find_files

      set_profiler do
        output = @cli_options[:output]

        modified_batch(core, files, output)

        output.close
      end

    rescue OptionParser::InvalidOption, OptionParser::MissingArgument
      puts $!
      exit 1
    end

    def modified_batch(core, files, output)
      if @core_options[:output_typeprof_version]
        output.puts "# TypeProf #{TypeProf::VERSION}"
        output.puts
      end

      i = 0
      show_files = files.select do |file|
        if @core_options[:display_indicator]
          $stderr << format("\r[%d/%d] %s\e[K", i, files.size, file)
          i += 1
        end

        content = File.read(file)
        res = core.update_file(file, content)

        if res
          true
        else
          output.puts "# failed to analyze: #{file}"
          false
        end
      end

      $stderr << "\r\e[K" if @core_options[:display_indicator]

      first = true
      show_files.each do |file|
        next if File.extname(file) == '.rbs'

        output.puts unless first
        first = false
        output.puts "# #{file}"

        if @core_options[:output_diagnostics]
          ignored_lines, ignored_blocks = collect_ignored_lines(file)

          diagnostics = []
          core.diagnostics(file) { |diag| diagnostics << diag }

          filtered_diagnostics = TypeProf::DiagnosticFilter.new(
            ignored_lines,
            ignored_blocks,
          ).call(diagnostics)

          filtered_diagnostics.each do |diag|
            output.puts "# #{diag.code_range}:#{diag.msg}"
          end
        end

        output.puts core.dump_declarations(file)
      end
    end

    def find_files
      files = []
      @cli_options[:argv].each do |path|
        if File.directory?(path)
          files.concat(Dir.glob("#{ path }/**/*.{rb,rbs}"))
        elsif File.file?(path)
          files << path
        else
          raise OptionParser::InvalidOption.new("no such file or directory -- #{ path }")
        end
      end

      if files.empty?
        exit if @cli_options[:display_version]
        raise OptionParser::InvalidOption.new("no input files")
      end

      files
    end

    def set_profiler
      if @cli_options[:stackprof]
        require "stackprof"
        out = "typeprof-stackprof-#{ @cli_options[:stackprof] }.dump"
        StackProf.start(mode: @cli_options[:stackprof], out: out, raw: true)
      end

      yield

    ensure
      if @cli_options[:stackprof] && defined?(StackProf)
        StackProf.stop
        StackProf.results
      end
    end
  end
end
