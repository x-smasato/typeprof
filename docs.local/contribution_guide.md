# コントリビューションガイド

このドキュメントでは、TypeProfプロジェクトへの貢献方法について説明します。

## 開発環境のセットアップ

### 前提条件

TypeProfの開発には、以下のものが必要です：

- Ruby 3.0以上
- Bundler

### リポジトリのクローン

まず、TypeProfのリポジトリをクローンします：

```bash
git clone https://github.com/ruby/typeprof.git
cd typeprof
```

### 依存関係のインストール

次に、依存関係をインストールします：

```bash
bundle install
```

### テストの実行

セットアップが正しく行われたことを確認するために、テストを実行します：

```bash
bundle exec rake test
```

## プロジェクト構造

TypeProfのプロジェクト構造は以下の通りです：

- `lib/`: TypeProfのソースコード
  - `lib/typeprof.rb`: メインエントリーポイント
  - `lib/typeprof/core/`: コアコンポーネント
  - `lib/typeprof/cli/`: CLIインターフェース
  - `lib/typeprof/lsp/`: LSP統合
- `test/`: テストコード
- `doc/`: ドキュメント
- `exe/`: 実行可能ファイル

## 開発ワークフロー

### ブランチの作成

新機能やバグ修正を開発する場合は、新しいブランチを作成します：

```bash
git checkout -b feature/your-feature-name
```

### コードの変更

TypeProfのコードを変更する際は、以下のガイドラインに従ってください：

1. **コードスタイル**: Rubyの標準的なコードスタイルに従ってください
2. **テスト**: 新機能やバグ修正には、対応するテストを追加してください
3. **ドキュメント**: 必要に応じてドキュメントを更新してください

### テストの実行

変更を加えた後は、テストを実行して問題がないことを確認してください：

```bash
bundle exec rake test
```

### コミットとプッシュ

変更が完了したら、コミットしてプッシュします：

```bash
git add .
git commit -m "Add your feature or fix"
git push origin feature/your-feature-name
```

### プルリクエストの作成

GitHubでプルリクエストを作成し、変更内容を説明してください。

## コードの理解

TypeProfのコードを理解するためのヒントを以下に示します：

### 主要コンポーネント

TypeProfは、以下の主要コンポーネントから構成されています：

1. **AST（抽象構文木）システム**: Rubyコードを解析し、抽象構文木として表現します
2. **型システム**: 様々な型を表現し、型の互換性を判断します
3. **Boxシステム**: 型の流れと変更を追跡します
4. **環境システム**: 解析のコンテキストを管理します
5. **サービスレイヤー**: 解析プロセスを調整します
6. **CLIインターフェース**: コマンドライン操作を処理します
7. **LSP統合**: Language Server Protocolをサポートし、エディタとの連携を可能にします

各コンポーネントの詳細については、対応するドキュメントを参照してください。

### 処理フロー

TypeProfの基本的な処理フローは以下の通りです：

1. **コードの解析**: Rubyコードを解析してASTを生成します
2. **定義フェーズ**: ASTから型の環境（クラス、モジュール、メソッドなどの定義）を構築します
3. **インストールフェーズ**: 型の流れをモデル化するBoxを作成します
4. **実行フェーズ**: Boxを実行して型情報を伝播します
5. **出力フェーズ**: 推論された型情報をRBS形式で出力します

## デバッグのヒント

TypeProfのコードをデバッグするためのヒントを以下に示します：

### ログの出力

デバッグ情報を出力するには、`pp`や`puts`を使用します：

```ruby
pp some_variable
puts "Debug: #{some_value}"
```

### テストケースの作成

特定の問題を再現するためのテストケースを作成することも有効です：

```ruby
# test/your_test_case.rb
require_relative "test_helper"

class YourTestCase < Test::Unit::TestCase
  def test_your_feature
    # テストコード
  end
end
```

### LSPデバッグ

LSP統合をデバッグする場合は、`--verbose`オプションを使用してログを出力できます：

```bash
typeprof --lsp --stdio --verbose
```

## 貢献のアイデア

TypeProfプロジェクトへの貢献のアイデアを以下に示します：

1. **バグ修正**: 既知のバグを修正する
2. **パフォーマンス改善**: 型推論のパフォーマンスを改善する
3. **新機能**: 新しい型推論機能を追加する
4. **ドキュメント**: ドキュメントを改善または追加する
5. **テスト**: テストカバレッジを向上させる

## コミュニティ

TypeProfのコミュニティに参加するには、以下のリソースを利用してください：

- [GitHub Issues](https://github.com/ruby/typeprof/issues): バグ報告や機能リクエスト
- [Ruby Slack](https://ruby-jp.github.io/): Rubyコミュニティの議論

## まとめ

TypeProfプロジェクトへの貢献は、Rubyエコシステムの型システムの発展に寄与する重要な活動です。このガイドに従って、TypeProfの改善に貢献してください。
