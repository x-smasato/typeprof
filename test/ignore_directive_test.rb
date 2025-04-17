require_relative 'helper'

module TypeProf
  class IgnoreDirectiveTest < Test::Unit::TestCase
    def test_tp_ignore
      result = run_typeprof('test/fixtures/ignore_directive/ignore_directive.rb')

      assert_match(/\(3,2\)-\(3,3\):failed to resolve overloads/, result)
      assert_not_match(/\(6,2\)-\(6,3\):failed to resolve overloads/, result)
      assert_not_match(/\(9,2\)-\(9,3\):failed to resolve overloads/, result)
      assert_not_match(/\(12,2\)-\(12,3\):failed to resolve overloads/, result)
      assert_not_match(/\(13,2\)-\(13,3\):failed to resolve overloads/, result)
      assert_match(/\(16,2\)-\(16,3\):failed to resolve overloads/, result)
    end

    private

    def run_typeprof(file)
      output = ''

      original_stdout = $stdout
      $stdout = StringIO.new(output)

      begin
        TypeProf::CLI::CLI.new(['--show-errors', file]).run
      ensure
        $stdout = original_stdout
      end

      output
    end
  end
end
