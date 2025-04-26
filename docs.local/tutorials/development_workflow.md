# TypeProf開発ワークフロー

このドキュメントでは、TypeProfの開発ワークフローについて説明します。

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

## 開発サイクル

TypeProfの開発サイクルは以下の通りです：

1. 機能の計画
2. コードの実装
3. テストの作成と実行
4. ドキュメントの更新
5. プルリクエストの作成

### 機能の計画

新機能を追加する前に、以下の点を考慮してください：

- 機能の目的と必要性
- 既存のコードとの統合方法
- 影響範囲と副作用

### コードの実装

TypeProfのコードを実装する際は、以下のガイドラインに従ってください：

- コードスタイルは既存のコードに合わせる
- 複雑なロジックにはコメントを追加する
- パフォーマンスを考慮する

### テストの作成と実行

TypeProfでは、以下の2種類のテストを使用しています：

1. ユニットテスト：`test/core/`ディレクトリ
2. シナリオテスト：`scenario/`ディレクトリ

#### ユニットテストの作成

ユニットテストは、`test/core/`ディレクトリに作成します：

```ruby
# test/core/your_test.rb
require_relative "../test_helper"

class YourTest < Test::Unit::TestCase
  def test_your_feature
    # テストコード
  end
end
```

#### シナリオテストの作成

シナリオテストは、`scenario/`ディレクトリに作成します：

```ruby
# scenario/your_scenario.rb
def foo(x)
  x + 1
end

p foo(42)
__END__
# Revealed types
#  your_scenario.rb:5 #=> Integer

# Classes
class Object
  def foo : (Integer) -> Integer
end
```

#### テストの実行

テストを実行するには、以下のコマンドを使用します：

```bash
# すべてのテストを実行
bundle exec rake test

# 特定のユニットテストを実行
bundle exec ruby test/core/your_test.rb

# 特定のシナリオテストを実行
bundle exec ruby test/scenario_compiler.rb scenario/your_scenario.rb
```

### ドキュメントの更新

コードを変更した場合は、関連するドキュメントも更新してください：

- ユーザー向けドキュメント：`doc/`ディレクトリ
- 開発者向けドキュメント：`docs.local/`ディレクトリ

### プルリクエストの作成

変更が完了したら、プルリクエストを作成します：

```bash
git checkout -b feature/your-feature-name
git add .
git commit -m "Add your feature"
git push origin feature/your-feature-name
```

GitHubでプルリクエストを作成し、変更内容を説明してください。

## デバッグ技法

TypeProfのコードをデバッグするための技法を以下に示します：

### ログの出力

デバッグ情報を出力するには、`pp`や`puts`を使用します：

```ruby
pp some_variable
puts "Debug: #{some_value}"
```

### TypeProfの実行

TypeProfを実行してデバッグするには、以下のコマンドを使用します：

```bash
# CLIモードで実行
bundle exec exe/typeprof your_file.rb

# LSPモードで実行（デバッグ情報付き）
bundle exec exe/typeprof --lsp --stdio --verbose
```

### デバッガーの使用

Rubyのデバッガーを使用してTypeProfをデバッグすることもできます：

```ruby
require "debug"
debugger # ここでデバッガーが起動
```


## コードの理解


TypeProfのコードを理解するためのヒントを以下に示します：

### 主要コンポーネント

TypeProfは、以下の主要コンポーネントから構成されています：

1. AST（抽象構文木）システム
2. 型システム
3. Boxシステム
4. 環境システム
5. サービスレイヤー
6. CLIインターフェース
7. LSP統合

### 処理フロー

TypeProfの基本的な処理フローは以下の通りです：

1. コードの解析：Rubyコードを解析してASTを生成
2. 定義フェーズ：ASTから型の環境を構築
3. インストールフェーズ：型の流れをモデル化するBoxを作成
4. 実行フェーズ：Boxを実行して型情報を伝播
5. 出力フェーズ：推論された型情報をRBS形式で出力

### コードの追跡

特定の機能のコードを追跡するには、以下の方法があります：

1. CLIエントリーポイント：`lib/typeprof/cli.rb`
2. LSPエントリーポイント：`lib/typeprof/lsp/server.rb`
3. コアサービス：`lib/typeprof/core/service.rb`

## パフォーマンスの最適化

TypeProfのパフォーマンスを最適化するためのヒントを以下に示します：

### メモ化の使用

頻繁に呼び出される計算は、メモ化を使用して最適化できます：

```ruby
def expensive_calculation(param)
  @cache ||= {}
  @cache[param] ||= begin
    # 計算処理
  end
end
```

### 型テーブルの最適化

型テーブルは、TypeProfのパフォーマンスに大きな影響を与えます。型テーブルの最適化には、以下の方法があります：

1. 型の共有：同じパラメータを持つ型オブジェクトを共有
2. 型の簡略化：複雑な型を簡略化して表現

### インクリメンタル解析

大規模なプロジェクトでは、インクリメンタル解析が重要です。変更されたファイルとその依存関係のみを再解析することで、パフォーマンスを向上させることができます。

## まとめ

このドキュメントでは、TypeProfの開発ワークフローについて説明しました。TypeProfの開発に貢献する際は、このワークフローに従ってください。
