# TypeProf ドキュメント

このディレクトリには、TypeProfの開発者向けドキュメントが含まれています。

## 目次

- [アーキテクチャ概要](./architecture.md)
- コンポーネント
  - [AST（抽象構文木）システム](./components/ast.md)
  - [型システム](./components/type_system.md)
  - [Boxシステム](./components/box_system.md)
  - [環境システム](./components/environment.md)
  - [サービスレイヤー](./components/service.md)
  - [CLIインターフェース](./components/cli.md)
  - [LSP統合](./components/lsp.md)
- [抽象値](./abstract_values.md)
- [コントリビューションガイド](./contribution_guide.md)

## TypeProfとは

TypeProfは、Rubyプログラムの型を静的に推論するための型アナライザです。型アノテーションを必要とせずに、Rubyコードから型情報を抽出し、RBS（Ruby Signature）形式で出力します。

詳細な使用方法については、[公式ドキュメント](../doc/doc.ja.md)を参照してください。
