# AST（抽象構文木）システム

AST（抽象構文木）システムは、TypeProfの中核をなすコンポーネントで、Rubyコードを解析して抽象構文木に変換し、型推論のための基盤を提供します。

## 概要

TypeProfのASTシステムは、Rubyコードを構文解析し、型推論に適した形式で表現します。AST内の各ノードは、Rubyコードの特定の構造（メソッド定義、メソッド呼び出し、条件分岐など）を表現します。

主要なファイル：
- <ref_file file="lib/typeprof/core/ast.rb" />
- <ref_file file="lib/typeprof/core/ast/base.rb" />
- その他 `lib/typeprof/core/ast/` ディレクトリ内のファイル

## 構文解析

TypeProfは、Rubyコードの解析にPrismパーサーを使用しています：

<ref_snippet file="lib/typeprof/core/ast.rb" lines="1-18" />

この`parse_rb`メソッドは、Rubyのソースコードを受け取り、それをPrismで解析し、TypeProf用のASTノードに変換します。

## ノード作成

AST内の各ノードは、`AST.create_node`メソッドによって作成されます：

<ref_snippet file="lib/typeprof/core/ast.rb" lines="22-32" />

このメソッドは、Prismが生成した生のノードとローカル環境を受け取り、TypeProf用の適切なASTノードを返します。

## ノードの種類

TypeProfのASTは、様々な種類のノードをサポートしています：

1. **定義ノード**: モジュール、クラス、メソッド定義
2. **制御ノード**: 条件分岐、ループ、例外処理
3. **定数ノード**: 定数の読み取りと書き込み
4. **変数ノード**: ローカル変数、インスタンス変数、クラス変数などの操作
5. **値ノード**: リテラル（整数、文字列、配列など）
6. **呼び出しノード**: メソッド呼び出し、ブロック

各ノードの詳細な実装は、対応するファイルで確認できます：

- `call.rb`: メソッド呼び出しに関連するノード
- `control.rb`: 制御構造に関連するノード
- `value.rb`: リテラルや値に関連するノード
- `method.rb`: メソッド定義に関連するノード
- `variable.rb`: 変数操作に関連するノード
- `const.rb`: 定数に関連するノード

## ノードの基本構造

すべてのASTノードは`Node`クラスを継承しており、以下のようなライフサイクルを持っています：

<ref_snippet file="lib/typeprof/core/ast/base.rb" lines="4-19" />

主なメソッド：
- `define`: 静的な型情報を定義します
- `install`: 型の流れを設定するBoxを作成します
- `uninstall`: 関連するBoxを削除します

## ASTノードのトラバース

ASTノードは、トラバースするためのメソッドを提供しています：

<ref_snippet file="lib/typeprof/core/ast/base.rb" lines="44-50" />

このメソッドを使用して、ASTツリー全体を巡回し、各ノードに対して操作を実行できます。

## AST変換の例

例えば、以下のようなRubyコード：

```ruby
def foo(x)
  x + 1
end
```

このコードは、TypeProfのASTでは以下のようなノード構造になります：

- DefNode（メソッド定義）
  - パラメータ: x
  - 本体: CallNode（メソッド呼び出し `+`）
    - レシーバ: LocalVariableReadNode（変数 `x` の読み取り）
    - 引数: IntegerNode（整数リテラル `1`）

この構造を通じて、TypeProfはRubyコードの型を推論します。
