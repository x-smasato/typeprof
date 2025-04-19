module TypeProf
  module Core
    module IgnoreDirective
      # Collect ranges of lines to ignore.
      class Scanner
        DISABLE_RE = /\s*#\stypeprof:disable$/
        ENABLE_RE = /\s*#\stypeprof:enable$/

        def self.collect(prism_result, src)
          lines = src.lines
          comments_by_line = Hash.new { |h, k| h[k] = [] }

          prism_result.comments.each do |c|
            comments_by_line[c.location.start_line] << c.location.slice
          end

          ranges = []
          current_start = nil

          1.upto(lines.size) do |ln|
            comment_text = comments_by_line[ln].join(' ')
            line_text = lines[ln - 1]

            disable = (comment_text =~ DISABLE_RE) || (line_text =~ DISABLE_RE)
            enable = (comment_text =~ ENABLE_RE) || (line_text =~ ENABLE_RE)

            if current_start # Inside a disable block.
              if enable # Enable directive found.
                ranges << (current_start..ln - 1)
                if line_text.strip.start_with?('#') # Block‑level enable directive.
                  current_start = nil # Close the disable block.
                else # Inline enable directive.
                  # Exclude lines from the start of the disable block up to the line before the inline enable directive.
                  current_start = ln + 1 # Disable block restarts on the next line.
                end
              end
            else # Outside a disable block.
              next unless disable

              if line_text.strip.start_with?('#') # Block‑level disable directive.
                current_start = ln + 1 # Disable block starts on the next line.
              else # Inline disable directive.
                ranges << (ln..ln) # Exclude only the current line.
              end
            end
          end

          # If no enable directive is found, exclude lines from the start of the disable block to the end of the file.
          ranges << (current_start..Float::INFINITY) if current_start && current_start <= lines.size

          ranges
        end
      end
    end
  end
end
