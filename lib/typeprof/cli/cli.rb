module TypeProf::CLI
  class CLI
    def initialize(argv)
      opt = OptionParser.new

      opt.banner = "Usage: #{opt.program_name} [options] files_or_dirs..."

      core_options = {}
      lsp_options = {}
      cli_options = {}

      output = nil
      rbs_collection_path = nil

      opt.separator ''
      opt.separator 'Options:'
      opt.on('-o OUTFILE', 'Output to OUTFILE instead of stdout') { |v| output = v }
      opt.on('-q', '--quiet', 'Quiet mode') do
        core_options[:display_indicator] = false
      end
      opt.on('-v', '--verbose', 'Verbose mode') do
        core_options[:show_errors] = true
      end
      opt.on('--version', 'Display typeprof version') { cli_options[:display_version] = true }
      opt.on('--collection PATH', 'File path of collection configuration') { |v| rbs_collection_path = v }
      opt.on('--no-collection', 'Ignore collection configuration') { rbs_collection_path = :no }
      opt.on('--lsp', 'LSP server mode') do |_v|
        core_options[:display_indicator] = false
        cli_options[:lsp] = true
      end

      opt.separator ''
      opt.separator 'Analysis output options:'
      opt.on('--[no-]show-typeprof-version', 'Display TypeProf version in a header') do |v|
        core_options[:output_typeprof_version] = v
      end
      opt.on('--[no-]show-errors', 'Display possible errors found during the analysis') do |v|
        core_options[:output_diagnostics] = v
      end
      opt.on('--[no-]show-parameter-names', 'Display parameter names for methods') do |v|
        core_options[:output_parameter_names] = v
      end
      opt.on('--[no-]show-source-locations', 'Display definition source locations for methods') do |v|
        core_options[:output_source_locations] = v
      end

      opt.separator ''
      opt.separator 'Advanced options:'
      opt.on('--[no-]stackprof MODE', /\Acpu|wall|object\z/, 'Enable stackprof (for debugging purpose)') do |v|
        cli_options[:stackprof] = v.to_sym
      end

      opt.separator ''
      opt.separator 'LSP options:'
      opt.on('--port PORT', Integer, 'Specify a port number to listen for requests on') { |v| lsp_options[:port] = v }
      opt.on('--stdio', 'Use stdio for LSP transport') { |v| lsp_options[:stdio] = v }

      opt.parse!(argv)

      if !cli_options[:lsp] && !lsp_options.empty?
        raise OptionParser::InvalidOption.new('lsp options with non-lsp mode')
      end

      @core_options = {
        rbs_collection: setup_rbs_collection(rbs_collection_path),
        display_indicator: $stderr.tty?,
        output_typeprof_version: true,
        output_errors: false,
        output_parameter_names: false,
        output_source_locations: false
      }.merge(core_options)

      @lsp_options = {
        port: 0,
        stdio: false
      }.merge(lsp_options)

      @cli_options = {
        argv:,
        output: output ? open(output, 'w') : $stdout.dup,
        display_version: false,
        stackprof: nil,
        lsp: false
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

      raise OptionParser::InvalidOption.new("file not found: #{path}") unless File.readable?(path)

      lock_path = RBS::Collection::Config.to_lockfile_path(Pathname(path))
      unless File.readable?(lock_path)
        raise OptionParser::InvalidOption.new("file not found: #{lock_path}; please run 'rbs collection install")
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
      puts $!.detailed_message(highlight: false).gsub(/^/, '---')
      raise
    end

    def collect_ignored_lines(path)
      ignored_lines = Set.new
      ignored_blocks = []

      begin
        original_path = path.end_with?('.rbe.rb') ? path.sub(/\.rbe\.rb$/, '.rb') : path
        content = File.read(original_path)
        tokens = Ripper.lex(content)

        line_tokens = Hash.new { |h, k| h[k] = [] }
        tokens.each do |(pos, type, token)|
          line_tokens[pos[0]] << [type, token, pos]
        end

        current_block_start = nil
        line_tokens.each do |line, tokens_in_line|
          has_code = tokens_in_line.any? { |type, _, _| type != :on_comment }
          has_disable = tokens_in_line.any? do |type, token, _|
            type == :on_comment && token.match?(/\s*#\s*typeprof:disable\b/)
          end
          has_enable = tokens_in_line.any? do |type, token, _|
            type == :on_comment && token.match?(/\s*#\s*typeprof:enable\b/)
          end

          if has_disable
            if has_code
              # コードと同じ行にdisableコメントがある場合は、その行を無視
              ignored_lines.add(line)
            elsif !current_block_start
              # コードがなく、ブロック開始されていない場合は新しいブロック開始
              current_block_start = line
            end
          elsif has_enable && current_block_start
            # enableコメントがある場合は範囲指定モードを終了
            ignored_blocks << [current_block_start, line]
            current_block_start = nil
          end
        end

        # ファイル末尾までブロックが続いていた場合
        ignored_blocks << [current_block_start, Float::INFINITY] if current_block_start

        if @core_options[:show_errors]
          warn "Debug: Collected ignored lines for #{original_path}: #{ignored_lines.to_a.sort}"
          warn "Debug: Collected ignored blocks for #{original_path}: #{ignored_blocks.inspect}"
        end
      rescue StandardError => e
        if @core_options[:show_errors]
          warn "Warning: Failed to collect ignored lines from #{original_path}: #{e.message}"
        end
      end

      [ignored_lines, ignored_blocks]
    end

    def run_cli
      core = TypeProf::Core::Service.new(@core_options)

      puts "typeprof #{TypeProf::VERSION}" if @cli_options[:display_version]

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

          if @core_options[:show_errors]
            warn "Debug: Ignored lines for #{file}: #{ignored_lines.to_a.sort.join(', ')}"
            warn "Debug: Ignored blocks for #{file}: #{ignored_blocks.inspect}"
          end

          diagnostics = []
          core.diagnostics(file) { |diag| diagnostics << diag }
          filtered_diagnostics = TypeProf::DiagnosticFilter.new(ignored_lines, ignored_blocks).call(diagnostics)

          if @core_options[:show_errors]
            warn "Debug: Total diagnostics: #{diagnostics.size}, Filtered: #{diagnostics.size - filtered_diagnostics.size}"
          end

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
          files.concat(Dir.glob("#{path}/**/*.{rb,rbs}"))
        elsif File.file?(path)
          files << path
        else
          raise OptionParser::InvalidOption.new("no such file or directory -- #{path}")
        end
      end

      if files.empty?
        exit if @cli_options[:display_version]
        raise OptionParser::InvalidOption.new('no input files')
      end

      files
    end

    def set_profiler
      if @cli_options[:stackprof]
        require 'stackprof'
        out = "typeprof-stackprof-#{@cli_options[:stackprof]}.dump"
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
