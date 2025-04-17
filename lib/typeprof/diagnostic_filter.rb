module TypeProf
  class DiagnosticFilter
    def initialize(ignored_lines)
      @ignored_lines = ignored_lines
    end

    def call(diagnostics)
      diagnostics.reject do |diagnostic|
        line = diagnostic.code_range.first.lineno
        @ignored_lines.include?(line)
      end
    end
  end
end
