require 'set'

module TypeProf
  class DirectiveParser
    def self.collect_ignored_lines(content)
      ignored_lines = Set.new
      ignored_blocks = []

      begin
        result = Prism.parse(content)
        return [ignored_lines, ignored_blocks] unless result.success?

        lines = content.lines

        line_comments = {}
        result.comments.each do |comment|
          line = comment.location.start_line
          line_comments[line] ||= []
          line_comments[line] << comment
        end

        code_lines = Set.new
        collect_code_lines(result.value, code_lines)

        current_block_start = nil

        1.upto(lines.size) do |line_num|
          comments = line_comments[line_num] || []
          comment_text = comments.map { |c| c.location.slice }.join(' ')
          line_text = lines[line_num - 1] || ''
          has_code = code_lines.include?(line_num)
          has_disable = comment_text.match?(/\s*#\s*typeprof:disable\b/) || line_text.match?(/\s*#\s*typeprof:disable\b/)
          has_enable = comment_text.match?(/\s*#\s*typeprof:enable\b/) || line_text.match?(/\s*#\s*typeprof:enable\b/)

          if current_block_start
            if has_enable
              ignored_lines.add(line_num) # Ignore the enable line too
              ignored_blocks << [current_block_start, line_num]
              current_block_start = nil
            else
              ignored_lines.add(line_num)
            end
          else
            if has_disable
              if has_code && !line_text.strip.start_with?('#') # If there's code and not a line-starting comment (inline disable)
                ignored_lines.add(line_num)
              else
                ignored_lines.add(line_num) # Ignore the disable line too
                current_block_start = line_num
              end
            end
          end
        end

        if current_block_start
          ignored_blocks << [current_block_start, Float::INFINITY]
          (current_block_start + 1).upto(lines.size) do |line_num|
            ignored_lines.add(line_num)
          end
        end
      rescue StandardError => e
        warn "Warning: Failed to collect ignored lines: #{e.message}"
      end

      [ignored_lines, ignored_blocks]
    end

    def self.collect_code_lines(node, lines)
      return unless node.is_a?(Prism::Node)

      if node.location
        start_line = node.location.start_line
        end_line = node.location.end_line
        (start_line..end_line).each { |line| lines.add(line) }
      end

      node.child_nodes.each { |child| collect_code_lines(child, lines) if child }
    end
  end
end
