# TypeProf LSP実装ドキュメント

## 概要

TypeProfのLSP（Language Server Protocol）実装は、Rubyコードの静的型解析をIDE/エディタに統合するための機能を提供します。この実装により、エディタ上でのコード補完、型情報の表示、定義へのジャンプなどの機能が利用可能になります。

## ファイル構成

TypeProfのLSP実装は、以下の主要ファイルで構成されています：

### messages.rb

このファイルは、LSPプロトコルで定義されているメッセージを処理するためのクラス群を提供します。

#### 主要クラスと機能

- `Message`：基底クラス。すべてのLSPメッセージ処理クラスの親クラスとして機能します。
  - `initialize(server, json)`：メッセージの初期化を行います。
  - `run`：メッセージの処理を実行します。サブクラスでオーバーライドされます。
  - `respond(result)`：クライアントへの応答を送信します。
  - `respond_error(error)`：エラー応答を送信します。
  - `notify(method, **params)`：通知を送信します。

- `Message::CancelRequest`：リクエストのキャンセルを処理します。

- `Message::Initialize`：クライアントからの初期化リクエストを処理します。
  - サーバーの機能（capabilities）を設定し、クライアントに返します。
  - ワークスペースフォルダを追加します。

- `Message::TextDocument::DidOpen`：ドキュメントが開かれた時の処理を行います。
  - テキストオブジェクトを作成し、サーバーの`open_texts`に保存します。
  - ファイルの更新と診断情報の公開を行います。

- `Message::TextDocument::DidChange`：ドキュメントが変更された時の処理を行います。
  - テキストに変更を適用し、ファイルを更新します。
  - 診断情報を再公開します。

- `Message::TextDocument::Definition`：定義へのジャンプ機能を提供します。
  - 指定された位置の定義を検索し、結果を返します。

- `Message::TextDocument::Hover`：ホバー情報（型情報など）を提供します。
  - カーソル位置の型情報を取得し、表示します。

- `Message::TextDocument::Completion`：コード補完機能を提供します。
  - 入力中のコードに基づいて候補を提案します。

- その他、`References`（参照検索）、`CodeLens`（コードレンズ）、`Rename`（リネーム）などの機能を処理するクラスも実装されています。

### server.rb

このファイルは、LSPサーバーの中核機能を実装し、クライアント（エディタ）とのやり取りを管理します。

#### 主要クラスと機能

- `Server`：LSPサーバーのメインクラス。
  - `start_stdio(core_options)`：標準入出力を使用してサーバーを起動します。
  - `start_socket(core_options)`：ソケット通信を使用してサーバーを起動します。
  - `initialize(core_options, reader, writer, ...)`：サーバーの初期化を行います。
  - `path_to_uri(path)`/`uri_to_path(url)`：パスとURIの相互変換を行います。
  - `add_workspaces(folders)`：ワークスペースフォルダを追加し、設定を読み込みます。
  - `target_path?(path)`：パスが解析対象かどうかを判定します。
  - `update_file(path, text)`：ファイルの内容を更新します。
  - `definitions(path, pos)`、`hover(path, pos)`などの各種LSP機能を実装するメソッド。
  - `run`：メッセージの受信と処理のメインループを実行します。
  - `send_response`、`send_notification`、`send_request`：各種メッセージを送信します。
  - `publish_diagnostics(uri)`：診断情報を公開します。

- `Reader`：LSPプロトコルに従ってメッセージを読み取るクラス。
  - `read`：プロトコルに従ってメッセージを読み取り、JSONとしてパースします。

- `Writer`：LSPプロトコルに従ってメッセージを書き込むクラス。
  - `write(**json)`：JSONオブジェクトをLSPプロトコル形式で書き込みます。

### text.rb

このファイルは、エディタ上のテキストドキュメントを管理するためのクラスを提供します。

#### 主要クラスと機能

- `Text`：テキストドキュメントを管理するクラス。
  - `initialize(path, text, version)`：テキストの初期化を行います。
  - `split(str)`：文字列を行に分割します。
  - `string`：全テキストを文字列として返します。
  - `apply_changes(changes, version)`：エディタからの変更を適用します。
    - 変更範囲に応じてテキストを更新します。
    - バージョンを更新します。
  - `validate`：テキストの形式を検証します。
  - `modify_for_completion(changes, pos)`：補完のためにテキストを一時的に変更します。
    - 「.」や「::」などの補完トリガー文字に応じた処理を行います。

### util.rb

このファイルは、LSP実装で使用するユーティリティ関数を提供します。

#### 主要機能

- `load_json_with_comments(path, **opts)`：コメント付きのJSONファイルを読み込む関数。
  - 単一行コメント（`//`）と複数行コメント（`/* */`）をサポートします。
  - JSONファイル内の末尾カンマも適切に処理します。
  - TypeProfの設定ファイル（`typeprof.conf.json`など）の読み込みに使用されます。

## LSP実装の連携と動作の流れ

TypeProfのLSP実装は、以下のような流れで動作します：

1. **サーバーの起動**：
   - `Server.start_stdio`または`Server.start_socket`によりサーバーが起動します。
   - クライアント（エディタ）との通信チャネルが確立されます。

2. **初期化**：
   - クライアントから`initialize`メッセージが送信されます。
   - `Message::Initialize`クラスが処理を行い、サーバーの機能（capabilities）を応答します。
   - ワークスペースフォルダが追加され、設定ファイルが読み込まれます。

3. **ファイルの操作**：
   - ファイルが開かれると、`Message::TextDocument::DidOpen`が処理を行います。
   - ファイルが変更されると、`Message::TextDocument::DidChange`が変更を適用します。
   - `Text`クラスがエディタ上のテキスト状態を管理します。

4. **言語機能の提供**：
   - ホバー情報：`Message::TextDocument::Hover`が型情報などを提供します。
   - 定義へのジャンプ：`Message::TextDocument::Definition`が定義位置を提供します。
   - コード補完：`Message::TextDocument::Completion`が補完候補を提供します。
   - その他、参照検索、リネームなどの機能も提供されます。

5. **診断情報の提供**：
   - ファイルの変更が行われるたびに、`Server.publish_diagnostics`が型エラーなどの診断情報を公開します。

## 設定とカスタマイズ

TypeProfのLSP機能は、プロジェクトルートの`typeprof.conf.json`（または`.jsonc`）ファイルで設定できます：

- `rbs_dir`：RBS（Ruby Signature）ファイルのディレクトリを指定します。
- `analysis_unit_dirs`：解析対象のディレクトリを指定します。
- `diagnostic_severity`：診断情報の重要度を指定します（`error`、`warning`、`info`、`hint`）。
- `typeprof_version`：使用するTypeProfのバージョンを指定します（現在は`experimental`のみサポート）。
