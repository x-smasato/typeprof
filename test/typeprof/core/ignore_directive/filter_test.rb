require_relative '../../../helper'

module TypeProf
  module Core
    module IgnoreDirective
      class FilterTest < Test::Unit::TestCase
        def test_ignore_when_line_is_in_range
          ranges = [1..3]
          filter = Filter.new(ranges)

          assert_equal(true, filter.ignore?(1))
          assert_equal(true, filter.ignore?(2))
          assert_equal(true, filter.ignore?(3))
        end

        def test_not_ignore_when_line_is_not_in_range
          ranges = [2..3]
          filter = Filter.new(ranges)

          assert_equal(false, filter.ignore?(1))
          assert_equal(false, filter.ignore?(4))
        end

        def test_with_empty_ranges
          filter = Filter.new([])

          assert_equal(false, filter.ignore?(1))
        end

        def test_with_infinite_range
          ranges = [2..Float::INFINITY]
          filter = Filter.new(ranges)

          assert_equal(false, filter.ignore?(1))
          assert_equal(true, filter.ignore?(2))
          assert_equal(true, filter.ignore?(100))
        end
      end
    end
  end
end
