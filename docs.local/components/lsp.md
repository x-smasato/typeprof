# LSP統合

LSP（Language Server Protocol）統合は、TypeProfをコードエディタと連携させるためのコンポーネントです。

## 概要

LSP統合は、主に<ref_file file="lib/typeprof/lsp/server.rb" />で定義されています。`Server`クラスは、LSPクライアント（コードエディタ）との通信を管理し、TypeProfの型推論機能をエディタに提供します。

## 基本構造

`Server`クラスの基本構造は以下の通りです：

<ref_snippet file="lib/typeprof/lsp/server.rb" lines="10-65" />

主なコンポーネント：
- `start_stdio`: 標準入出力を使用してLSPサーバーを起動するメソッド
- `start_socket`: ソケットを使用してLSPサーバーを起動するメソッド
- `initialize`: サーバーの初期化処理
- `reader`: LSPクライアントからのメッセージを読み取るためのリーダー
- `writer`: LSPクライアントへのメッセージを書き込むためのライター

## ワークスペースの管理

LSPサーバーは、ワークスペース（プロジェクトディレクトリ）を管理します：

<ref_snippet file="lib/typeprof/lsp/server.rb" lines="75-114" />

このメソッドは、以下の処理を行います：
1. ワークスペース内の設定ファイル（`typeprof.conf.json`）を検索
2. 設定ファイルから解析ユニットディレクトリとRBSディレクトリを読み込み
3. 各解析ユニットディレクトリに対してTypeProfのコアサービスを初期化

## ファイル管理

LSPサーバーは、ワークスペース内のファイルを管理します：

<ref_snippet file="lib/typeprof/lsp/server.rb" lines="143-147" />

このメソッドは、ファイルの更新をすべての関連するコアサービスに伝播します。

## LSPリクエストの処理

LSPサーバーは、様々なLSPリクエストを処理するメソッドを提供します：

### 定義の検索

定義の検索は、`definitions`メソッドで処理されます：

<ref_snippet file="lib/typeprof/lsp/server.rb" lines="149-153" />

### 型定義の検索

型定義の検索は、`type_definitions`メソッドで処理されます：

<ref_snippet file="lib/typeprof/lsp/server.rb" lines="155-159" />

### 参照の検索

参照の検索は、`references`メソッドで処理されます：

<ref_snippet file="lib/typeprof/lsp/server.rb" lines="161-165" />

### ホバー情報

ホバー情報は、`hover`メソッドで取得できます：

<ref_snippet file="lib/typeprof/lsp/server.rb" lines="167-173" />

### コードレンズ

コードレンズは、`code_lens`メソッドで処理されます：

<ref_snippet file="lib/typeprof/lsp/server.rb" lines="175-179" />

### 補完

補完は、`completion`メソッドで処理されます：

<ref_snippet file="lib/typeprof/lsp/server.rb" lines="181-185" />

### リネーム

リネームは、`rename`メソッドで処理されます：

<ref_snippet file="lib/typeprof/lsp/server.rb" lines="187-191" />

## サーバーの実行

LSPサーバーの実行は、`run`メソッドで管理されます：

<ref_snippet file="lib/typeprof/lsp/server.rb" lines="193-212" />

このメソッドは、以下の処理を行います：
1. LSPクライアントからのメッセージを読み取り
2. メッセージの種類（リクエスト、通知、レスポンス）を判断
3. 適切なメッセージハンドラを呼び出し
4. 必要に応じてレスポンスを送信

## 診断情報の公開

LSPサーバーは、診断情報（型エラーや警告）をクライアントに公開します：

<ref_snippet file="lib/typeprof/lsp/server.rb" lines="238-254" />

このメソッドは、各ファイルの診断情報を収集し、LSPクライアントに送信します。

## LSP通信の処理

LSPサーバーは、LSPクライアントとの通信を処理するためのクラスも提供しています：

### Reader

`Reader`クラスは、LSPクライアントからのメッセージを読み取ります：

<ref_snippet file="lib/typeprof/lsp/server.rb" lines="257-276" />

### Writer

`Writer`クラスは、LSPクライアントへのメッセージを書き込みます：

<ref_snippet file="lib/typeprof/lsp/server.rb" lines="279-292" />

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
