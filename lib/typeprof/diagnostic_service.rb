module TypeProf
  class DiagnosticService
    def self.filter_diagnostics(diagnostics, source_text)
      return diagnostics unless source_text

      ignored_lines, ignored_blocks = DirectiveParser.collect_ignored_lines(source_text)
      DiagnosticFilter.new(ignored_lines, ignored_blocks).call(diagnostics)
    end
  end
end
