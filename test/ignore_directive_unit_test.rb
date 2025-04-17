require_relative "helper"

module TypeProf
  class IgnoreDirectiveTest < Test::Unit::TestCase
    def test_tp_ignore
      result = run_typeprof("test/ignore_directive.rb")
      
      assert_not_match(/1 \+ "b".*failed to resolve overloads/, result)
      
      assert_match(/1 \+ "a".*failed to resolve overloads/, result)
      assert_match(/1 \+ "c".*failed to resolve overloads/, result)
      assert_match(/1 \+ "d".*failed to resolve overloads/, result)
    end
    
    def test_tp_ignore_next_line
      result = run_typeprof("test/ignore_directive_next_line.rb")
      
      assert_not_match(/1 \+ "c".*failed to resolve overloads/, result)
      
      assert_match(/1 \+ "a".*failed to resolve overloads/, result)
      assert_match(/1 \+ "d".*failed to resolve overloads/, result)
    end
    
    private
    
    def run_typeprof(file)
      output = ""
      
      original_stdout = $stdout
      $stdout = StringIO.new(output)
      
      begin
        TypeProf::CLI::CLI.new(["--show-errors", file]).run
      ensure
        $stdout = original_stdout
      end
      
      output
    end
  end
end
