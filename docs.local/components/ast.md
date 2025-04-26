# AST（抽象構文木）システム

AST（抽象構文木）システムは、TypeProfの中核をなすコンポーネントで、Rubyコードを解析して抽象構文木に変換し、型推論のための基盤を提供します。

## 概要

TypeProfのASTシステムは、Rubyコードを構文解析し、型推論に適した形式で表現します。AST内の各ノードは、Rubyコードの特定の構造（メソッド定義、メソッド呼び出し、条件分岐など）を表現します。

主要なファイル：
- [lib/typeprof/core/ast.rb](../../lib/typeprof/core/ast.rb)
- [lib/typeprof/core/ast/base.rb](../../lib/typeprof/core/ast/base.rb)
- その他 [lib/typeprof/core/ast/](../../lib/typeprof/core/ast/) ディレクトリ内のファイル

## 構文解析

TypeProfは、Rubyコードの解析にPrismパーサーを使用しています：

[lib/typeprof/core/ast.rb](../../lib/typeprof/core/ast.rb)

この`parse_rb`メソッドは、Rubyのソースコードを受け取り、それをPrismで解析し、TypeProf用のASTノードに変換します。

## ノード作成

AST内の各ノードは、`AST.create_node`メソッドによって作成されます：

[lib/typeprof/core/ast.rb](../../lib/typeprof/core/ast.rb)

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

[lib/typeprof/core/ast/base.rb](../../lib/typeprof/core/ast/base.rb)

主なメソッド：
- `define`: 静的な型情報を定義します
- `install`: 型の流れを設定するBoxを作成します
- `uninstall`: 関連するBoxを削除します

## ASTノードのトラバース

ASTノードは、トラバースするためのメソッドを提供しています：

[lib/typeprof/core/ast/base.rb](../../lib/typeprof/core/ast/base.rb)

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

## 実装詳細

### ノードの実装パターン

TypeProfのASTノードは、以下のようなパターンで実装されています：

```ruby
class SomeNode < Node
  def initialize(node, env)
    super
    @some_attr = node.some_attr
  end

  def define
    # 静的な型情報を定義
  end

  def install0
    # 型の流れを設定するBoxを作成
  end
end
```

### 主要なノード型の詳細

#### DefNode（メソッド定義）

メソッド定義を表現するノードです：

[lib/typeprof/core/ast/method.rb](../../lib/typeprof/core/ast/method.rb)

このノードは、メソッド名、引数、本体を保持し、メソッドの型シグネチャを定義します。

#### CallNode（メソッド呼び出し）

メソッド呼び出しを表現するノードです：

[lib/typeprof/core/ast/call.rb](../../lib/typeprof/core/ast/call.rb)

このノードは、レシーバ、メソッド名、引数を保持し、メソッド呼び出しの型の流れを設定します。

#### IfNode（条件分岐）

条件分岐を表現するノードです：

[lib/typeprof/core/ast/control.rb](../../lib/typeprof/core/ast/control.rb)

このノードは、条件式、then節、else節を保持し、条件分岐の型の流れを設定します。

## デバッグ方法

ASTノードをデバッグするには、以下の方法があります：

### ASTの表示

```ruby
pp TypeProf::Core::AST.parse_rb(code)
```

このコードを使用して、Rubyコードから生成されたASTを表示できます。

### ノードの詳細情報の表示

```ruby
def debug_node(node)
  puts "Node type: #{node.class}"
  puts "Node attributes: #{node.instance_variables}"
  # その他の詳細情報
end
```

## カスタムノードの追加方法

TypeProfに新しいノード型を追加するには、以下の手順に従います：

1. 適切なファイル（例：`lib/typeprof/core/ast/your_node.rb`）にノードクラスを定義
2. `Node`クラスを継承
3. `define`メソッドと`install0`メソッドを実装
4. `AST.create_node`メソッドで新しいノード型に対応するケースを追加

```ruby
class YourNode < Node
  def initialize(node, env)
    super
    # 初期化処理
  end

  def define
    # 静的な型情報を定義
  end

  def install0
    # 型の流れを設定するBoxを作成
  end
end
```

そして、`AST.create_node`メソッドに以下のように追加します：

```ruby
def self.create_node(node, env)
  case node
  # 既存のケース
  # ...
  when Prism::YourNodeType
    YourNode.new(node, env)
  end
end
```

## ASTノードの型推論プロセス

ASTノードの型推論プロセスは、以下の2つの主要なフェーズで構成されています：

1. **定義フェーズ（define）**: このフェーズでは、静的な型情報（クラス、モジュール、メソッドの定義など）が収集されます。
2. **インストールフェーズ（install）**: このフェーズでは、型の流れを表現するBoxが作成され、型推論のための準備が行われます。

例えば、メソッド定義の場合：

```ruby
def foo(x)
  x + 1
end
```

1. **定義フェーズ**: `DefNode`の`define`メソッドが呼び出され、メソッド`foo`の定義が環境に登録されます。
2. **インストールフェーズ**: `DefNode`の`install0`メソッドが呼び出され、メソッド本体の型の流れを表現するBoxが作成されます。

## ASTノードの最適化

TypeProfのASTノードは、型推論の効率を向上させるために、いくつかの最適化が施されています：

1. **メモ化**: 同じノードに対する操作結果をキャッシュすることで、計算の重複を避けます。
2. **早期終了**: 型が確定した場合、それ以上の解析を行わないようにします。
3. **型の絞り込み**: 条件分岐などで型が絞り込まれた場合、その情報を利用して型推論の精度を向上させます。

これらの最適化により、TypeProfは大規模なRubyコードに対しても効率的に型推論を行うことができます。
