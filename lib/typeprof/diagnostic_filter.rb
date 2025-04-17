module TypeProf
  class DiagnosticFilter
    def initialize(ignored_lines, ignored_blocks = [])
      @ignored_lines = ignored_lines
      @ignored_blocks = ignored_blocks
    end

    def call(diagnostics)
      return [] if diagnostics.empty?

      diagnostics.reject do |diagnostic|
        line = diagnostic.code_range.first.lineno
        is_ignored_line = @ignored_lines.include?(line)
        is_ignored_block = in_ignored_block?(line)
        is_ignored = is_ignored_line || is_ignored_block

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

        result
      end
    end
  end
end
