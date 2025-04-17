require_relative "helper"

module TypeProf
  class IgnoreDirectiveTest < Test::Unit::TestCase
    def test_tp_ignore
      result = run_typeprof("test/fixtures/ignore_directive/ignore_directive.rb")
      
      assert_not_match(/\(7,2\)-\(7,3\):failed to resolve overloads/, result)
      
      assert_match(/\(4,2\)-\(4,3\):failed to resolve overloads/, result)
      assert_match(/\(10,2\)-\(10,3\):failed to resolve overloads/, result)
      assert_match(/\(13,2\)-\(13,3\):failed to resolve overloads/, result)
    end
    
    def test_tp_ignore_next_line
      result = run_typeprof("test/fixtures/ignore_directive/ignore_directive_next_line.rb")
      
      assert_not_match(/\(8,2\)-\(8,3\):failed to resolve overloads/, result)
      
      assert_match(/\(3,2\)-\(3,3\):failed to resolve overloads/, result)
      assert_match(/\(10,2\)-\(10,3\):failed to resolve overloads/, result)
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
