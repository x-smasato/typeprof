module TypeProf
  class SourceFile
    attr_reader :path, :text, :ast, :ignored_lines, :ignored_blocks

    def initialize(path, text, genv)
      @path, @text = path, text
      @genv = genv

      @ast = Core::AST.parse_rb(path, text)
      @ignored_lines, @ignored_blocks = DirectiveParser.collect_ignored_lines(text)
    end

    def raw_diags
      @ast&.diagnostics(@genv)&.to_a || []
    end

    def filtered_diags
      DiagnosticFilter.new(@ignored_lines, @ignored_blocks).call(raw_diags)
    end
  end
end
