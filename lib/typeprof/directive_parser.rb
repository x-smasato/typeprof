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

        # コメントを行ごとに整理
        line_comments = {}
        result.comments.each do |comment|
          line = comment.location.start_line
          line_comments[line] ||= []
          line_comments[line] << comment
        end

        code_lines = Set.new
        collect_code_lines(result.value, code_lines)

        current_block_start = nil

        # 各行を1行ずつ確認（1-indexed）
        1.upto(lines.size) do |line_num|
          comments = line_comments[line_num] || []
          comment_text = comments.map { |c| c.location.slice }.join(' ')
          line_text = lines[line_num - 1] || ''
          has_code = code_lines.include?(line_num)
          has_disable = comment_text.match?(/\s*#\s*typeprof:disable\b/) || line_text.match?(/\s*#\s*typeprof:disable\b/)
          has_enable = comment_text.match?(/\s*#\s*typeprof:enable\b/) || line_text.match?(/\s*#\s*typeprof:enable\b/)

          if current_block_start
            # ブロック内にいる場合
            if has_enable
              # enable コメントが見つかったらブロック終了
              ignored_lines.add(line_num) # enable 行も無視
              ignored_blocks << [current_block_start, line_num]
              current_block_start = nil
            else
              # ブロック内で enable 以外なら無視
              ignored_lines.add(line_num)
            end
          else
            if has_disable
              if has_code && !line_text.strip.start_with?('#') # コードがあり、行頭コメントではない場合 (インラインdisable)
                # コードと同じ行にある disable はその行だけ無視 (ブロック開始しない)
                ignored_lines.add(line_num)
              else
                # コードがない行、または行頭コメントの disable はブロック開始
                ignored_lines.add(line_num) # disable 行も無視
                current_block_start = line_num
              end
            end
            # ブロック外で disable も enable もない行は 何もしない (無視しない)
          end
        end

        # ファイル末尾までブロックが続いていた場合
        if current_block_start
          ignored_blocks << [current_block_start, Float::INFINITY]
          # ファイル末尾までの行を無視対象に追加
          (current_block_start + 1).upto(lines.size) do |line_num|
            ignored_lines.add(line_num)
          end
        end
      rescue StandardError => e
        warn "Warning: Failed to collect ignored lines: #{e.message}"
      end

      [ignored_lines, ignored_blocks]
    end

    # ノードから行番号を収集するヘルパーメソッド
    def self.collect_code_lines(node, lines)
      return unless node.is_a?(Prism::Node)

      # 現在のノードの行番号を追加
      if node.location
        start_line = node.location.start_line
        end_line = node.location.end_line
        (start_line..end_line).each { |line| lines.add(line) }
      end

      # 子ノードを再帰的に処理
      node.child_nodes.each { |child| collect_code_lines(child, lines) if child }
    end
  end
end