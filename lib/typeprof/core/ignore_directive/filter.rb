module TypeProf
  module Core
    module IgnoreDirective
      # Filter lines to ignore.
      class Filter
        def initialize(ranges)
          @ranges = ranges
        end

        def ignore?(line)
          @ranges.any? { |r| r.cover?(line) }
        end
      end
    end
  end
end
