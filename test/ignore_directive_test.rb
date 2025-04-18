require_relative 'helper'
require 'stringio'

module TypeProf
  class IgnoreDirectiveTest < Test::Unit::TestCase
    def test_ignore_directive
      file_path = File.join(__dir__, "fixtures/ignore_directive/ignore_directive.rb")
      
      output = StringIO.new
      original_stdout = $stdout
      $stdout = output
      
      begin
        TypeProf::CLI::CLI.new(['--show-errors', file_path]).run
      ensure
        $stdout = original_stdout
      end
      
      result = output.string
      
      assert_match(/\(3,2\)-\(3,3\): failed to resolve overloads/, result)
      assert_not_match(/\(6,2\)-\(6,3\): failed to resolve overloads/, result)
      assert_not_match(/\(9,2\)-\(9,3\): failed to resolve overloads/, result)
      assert_not_match(/\(12,2\)-\(12,3\): failed to resolve overloads/, result)
      assert_not_match(/\(13,2\)-\(13,3\): failed to resolve overloads/, result)
      assert_match(/\(16,2\)-\(16,3\): failed to resolve overloads/, result)
    end
  end
end
