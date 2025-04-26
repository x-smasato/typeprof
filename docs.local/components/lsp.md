# LSP統合

LSP（Language Server Protocol）統合は、TypeProfをコードエディタと連携させるためのコンポーネントです。

## 概要

LSP統合は、主に[lib/typeprof/lsp/server.rb](../../lib/typeprof/lsp/server.rb)で定義されています。`Server`クラスは、LSPクライアント（コードエディタ）との通信を管理し、TypeProfの型推論機能をエディタに提供します。

## 基本構造

`Server`クラスの基本構造は以下の通りです：

主なコンポーネント：
- `start_stdio`: 標準入出力を使用してLSPサーバーを起動するメソッド
- `start_socket`: ソケットを使用してLSPサーバーを起動するメソッド
- `initialize`: サーバーの初期化処理
- `reader`: LSPクライアントからのメッセージを読み取るためのリーダー
- `writer`: LSPクライアントへのメッセージを書き込むためのライター

## ワークスペースの管理

LSPサーバーは、ワークスペース（プロジェクトディレクトリ）を管理します：

このメソッドは、以下の処理を行います：
1. ワークスペース内の設定ファイル（`typeprof.conf.json`）を検索
2. 設定ファイルから解析ユニットディレクトリとRBSディレクトリを読み込み
3. 各解析ユニットディレクトリに対してTypeProfのコアサービスを初期化

## ファイル管理

LSPサーバーは、ワークスペース内のファイルを管理します：

このメソッドは、ファイルの更新をすべての関連するコアサービスに伝播します。

## LSPリクエストの処理

LSPサーバーは、様々なLSPリクエストを処理するメソッドを提供します：

### 定義の検索

定義の検索は、`definitions`メソッドで処理されます：

### 型定義の検索

型定義の検索は、`type_definitions`メソッドで処理されます：

### 参照の検索

参照の検索は、`references`メソッドで処理されます：

### ホバー情報

ホバー情報は、`hover`メソッドで取得できます：

### コードレンズ

コードレンズは、`code_lens`メソッドで処理されます：

### 補完

補完は、`completion`メソッドで処理されます：

### リネーム

リネームは、`rename`メソッドで処理されます：

## サーバーの実行

LSPサーバーの実行は、`run`メソッドで管理されます：

このメソッドは、以下の処理を行います：
1. LSPクライアントからのメッセージを読み取り
2. メッセージの種類（リクエスト、通知、レスポンス）を判断
3. 適切なメッセージハンドラを呼び出し
4. 必要に応じてレスポンスを送信

## 診断情報の公開

LSPサーバーは、診断情報（型エラーや警告）をクライアントに公開します：

このメソッドは、各ファイルの診断情報を収集し、LSPクライアントに送信します。

## LSP通信の処理

LSPサーバーは、LSPクライアントとの通信を処理するためのクラスも提供しています：

### Reader

`Reader`クラスは、LSPクライアントからのメッセージを読み取ります：

### Writer

`Writer`クラスは、LSPクライアントへのメッセージを書き込みます：

## LSP統合の使用例

TypeProfのLSP統合は、以下のように使用できます：

```bash
# 標準入出力を使用してLSPサーバーを起動
typeprof --lsp --stdio

# ソケットを使用してLSPサーバーを起動
typeprof --lsp --port 8080
```

また、Visual Studio CodeなどのエディタでTypeProfのLSP拡張機能を使用することもできます。

## LSP統合の重要性

LSP統合は、TypeProfをコードエディタと連携させるための重要なコンポーネントであり、以下の役割を果たします：

1. **リアルタイム型チェック**: コード編集中にリアルタイムで型チェックを提供
2. **コード補完**: 型情報に基づいたコード補完を提供
3. **定義ジャンプ**: シンボルの定義へのジャンプをサポート
4. **型情報の表示**: ホバー時に型情報を表示

LSP統合の理解は、TypeProfを開発環境に統合し、効率的に使用するために重要です。

## 設定ファイル

TypeProfのLSP統合は、`typeprof.conf.json`または`typeprof.conf.jsonc`という設定ファイルを使用します。この設定ファイルは、プロジェクトのルートディレクトリに配置します。

設定ファイルの例：

```json
{
  "analyzeSources": [
    "lib/**/*.rb",
    "app/**/*.rb"
  ],
  "loadSignatures": [
    "sig/**/*.rbs"
  ],
  "excludes": [
    "lib/vendor/**/*.rb"
  ],
  "logLevel": "info"
}
```

主な設定オプション：
- `analyzeSources`: 解析対象のRubyファイルのパターン
- `loadSignatures`: 読み込むRBSファイルのパターン
- `excludes`: 解析から除外するファイルのパターン
- `logLevel`: ログレベル（debug, info, warn, error）

## エディタとの統合

### Visual Studio Code

Visual Studio CodeでTypeProfを使用するには、以下の拡張機能をインストールします：

```bash
code --install-extension mame.ruby-typeprof
```

拡張機能の設定:

```json
{
  "ruby.typeprof.enabled": true,
  "ruby.typeprof.logLevel": "info"
}
```

### その他のエディタ

TypeProfはLSPをサポートしているため、LSPクライアントを実装しているエディタであれば統合が可能です。例えば、Vim、Emacs、Atomなどで使用できます。

## 高度な機能

### カスタムLSPリクエストの実装

TypeProfのLSP統合は拡張可能で、カスタムリクエストを実装することができます。例えば、特定のメソッドの利用箇所を検索する機能などを追加できます。

カスタムリクエストの実装例：

```ruby
class Server
  # 既存のコード...

  def custom_request(params)
    # カスタムリクエストの処理
    # ...
    return result
  end

  private

  def handle_request(id, method, params)
    case method
    # 既存のケース...
    when "typeprof/customRequest"
      result = custom_request(params)
      response(id, result)
    end
  end
end
```

### パフォーマンスの最適化

TypeProfのLSP統合では、パフォーマンスを最適化するためのいくつかの方法があります：

1. インクリメンタル解析: ファイルが変更された場合、そのファイルとその依存関係のみを再解析
2. キャッシュ: 解析結果をキャッシュして再利用
3. 並列処理: 複数のファイルを並列で解析

これらの最適化は、LSPサーバーの`initialize`メソッドでの設定や、コアサービスの実装で行われています。

## デバッグとトラブルシューティング

LSP統合のデバッグには、以下の方法があります：

1. ログの有効化:
   ```bash
   typeprof --lsp --stdio --verbose
   ```

2. LSPメッセージの検査:
   ```ruby
   def inspect_message(message, direction)
     File.open("/tmp/typeprof-lsp.log", "a") do |f|
       f.puts "#{direction}: #{message.inspect}"
     end
   end
   ```

3. エディタの開発者ツールの使用:
   Visual Studio Codeの場合、`Developer: Toggle Developer Tools`コマンドを使用してデバッガーを開くことができます。

## LSP統合の拡張方法

TypeProfのLSP統合を拡張するには、以下の手順に従います：

1. `Server`クラスに新しいメソッドを追加
2. `handle_request`メソッドに新しいリクエストタイプを追加
3. 必要に応じて、コアサービスに新しい機能を追加

例えば、新しい診断タイプを追加するには：

```ruby
class Server
  # 既存のコード...

  def custom_diagnostics(uri)
    # カスタム診断の実装
    # ...
    return diagnostics
  end

  def publish_diagnostics
    # 既存のコード...

    # カスタム診断の追加
    custom_diags = custom_diagnostics(uri)
    diagnostics.concat(custom_diags)

    # 既存のコード...
  end
end
```
