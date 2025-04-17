module TypeProf
  class DiagnosticFilter
    def initialize(ignored_lines, ignored_blocks = [], debug = false)
      @ignored_lines = ignored_lines
      @ignored_blocks = ignored_blocks
      @debug = debug
    end

    def call(diagnostics)
      return [] if diagnostics.empty?

      if @debug
        puts "DiagnosticFilter: Ignored lines: #{@ignored_lines.to_a.sort.join(', ')}"
        puts "DiagnosticFilter: Ignored blocks: #{@ignored_blocks.inspect}"
      end

      diagnostics.reject do |diagnostic|
        line = diagnostic.code_range.first.lineno
        is_ignored_line = @ignored_lines.include?(line)
        is_ignored_block = in_ignored_block?(line)
        is_ignored = is_ignored_line || is_ignored_block

        if @debug
          # warn や puts を使用する (例)
          # warn "DiagnosticFilter: Checking line #{line}: ignored_line=#{is_ignored_line}, ignored_block=#{is_ignored_block}, final=#{is_ignored}"
        end

        is_ignored
      end
    end

    private

    def in_ignored_block?(line)
      @ignored_blocks.any? do |start_line, end_line|
        result = if end_line == Float::INFINITY
                   # disable コメント行の *次* の行以降が対象
                   line > start_line
                 else
                   # disable コメント行の *次* の行から enable コメント行の *前* の行までが対象
                   line > start_line && line < end_line
                 end

        if @debug && result
          # warn や puts を使用する (例)
          # warn "DiagnosticFilter: Line #{line} is in block [#{start_line}, #{end_line}]"
        end

        result
      end
    end
  end
end
