# TypeProf Core AST ドキュメント

## 概要

TypeProfのコアASTモジュールは、Rubyコードを抽象構文木（AST）として表現し、型解析を行うための基盤を提供します。このモジュールは、Prismパーサーによって生成された構文木を、TypeProfの型解析に適した形式に変換します。

## ディレクトリ構造

`lib/typeprof/core/ast/` ディレクトリには以下のファイルが含まれています：

- `base.rb` - ASTノードの基本クラスと共通機能
- `call.rb` - メソッド呼び出しに関連するノード
- `const.rb` - 定数の読み書きに関連するノード
- `control.rb` - 制御構造（if、while、caseなど）に関連するノード
- `method.rb` - メソッド定義に関連するノード
- `value.rb` - リテラル値に関連するノード
- `variable.rb` - 変数の読み書きに関連するノード
- `module.rb` - モジュール・クラス定義に関連するノード
- `pattern.rb` - パターンマッチングに関連するノード
- `sig_decl.rb` - 型シグネチャ宣言に関連するノード
- `sig_type.rb` - 型シグネチャの型表現に関連するノード
- `misc.rb` - その他のノード
- `meta.rb` - メタプログラミングに関連するノード

## 主要なクラスと機能

### 1. AST::Node (base.rb)

すべてのASTノードの基底クラスです。以下の主要なメソッドを提供します：

- `define(genv)` - ノードの静的な定義を行う
- `install(genv)` - ノードを型グラフにインストールする
- `undefine(genv)` - ノードの定義を解除する
- `uninstall(genv)` - ノードを型グラフから削除する
- `diff(prev_node)` - 前のノードとの差分を計算する
- `retrieve_at(pos)` - 指定された位置にあるノードを取得する

各ノードは以下の属性を持ちます：
- `@raw_node` - Prismパーサーから得られた元のノード
- `@lenv` - ローカル環境（スコープ情報）
- `@prev_node` - 差分計算用の前のノード
- `@static_ret` - 静的な戻り値
- `@ret` - 実際の戻り値
- `@changes` - 変更セット

### 2. メソッド呼び出しノード (call.rb)

メソッド呼び出しを表現するノード群：

- `CallBaseNode` - メソッド呼び出しの基底クラス
- `CallNode` - 通常のメソッド呼び出し
- `SuperNode` - super呼び出し
- `YieldNode` - yield呼び出し
- `OperatorNode` - 演算子メソッド呼び出し
- `IndexReadNode` - 配列/ハッシュの要素読み取り
- `IndexWriteNode` - 配列/ハッシュの要素書き込み
- `CallReadNode` - メソッド呼び出しによる読み取り
- `CallWriteNode` - メソッド呼び出しによる書き込み

これらのノードは、レシーバー、メソッド名、引数、ブロックなどの情報を保持し、型解析時にメソッド呼び出しの型を推論します。

### 3. 定数ノード (const.rb)

定数の読み書きを表現するノード：

- `ConstantReadNode` - 定数の読み取り
- `ConstantWriteNode` - 定数の書き込み

これらのノードは、定数パスの解決と型の追跡を行います。

### 4. 制御構造ノード (control.rb)

制御フローを表現するノード群：

- `BranchNode` - 分岐の基底クラス
- `IfNode` - if文
- `UnlessNode` - unless文
- `LoopNode` - ループの基底クラス
- `WhileNode` - while文
- `UntilNode` - until文
- `BreakNode` - break文
- `NextNode` - next文
- `RedoNode` - redo文
- `CaseNode` - case文
- `CaseMatchNode` - case-in文（パターンマッチング）
- `AndNode` - &&演算子
- `OrNode` - ||演算子
- `ReturnNode` - return文
- `RescueNode` - rescue節
- `BeginNode` - begin-end文
- `RetryNode` - retry文
- `RescueModifierNode` - rescue修飾子

これらのノードは、制御フローの分岐と合流を管理し、各分岐での型の変化を追跡します。

### 5. メソッド定義ノード (method.rb)

メソッド定義を表現するノード：

- `DefNode` - メソッド定義
- `AliasNode` - メソッドのエイリアス
- `UndefNode` - メソッドの未定義化

`DefNode`は、メソッドのパラメータ、本体、RBSコメントによる型注釈などを処理します。

### 6. 値ノード (value.rb)

リテラル値を表現するノード群：

- `SelfNode` - self
- `LiteralNode` - リテラルの基底クラス
- `NilNode` - nil
- `TrueNode` - true
- `FalseNode` - false
- `IntegerNode` - 整数
- `FloatNode` - 浮動小数点数
- `RationalNode` - 有理数
- `ComplexNode` - 複素数
- `SymbolNode` - シンボル
- `InterpolatedSymbolNode` - 式展開を含むシンボル
- `StringNode` - 文字列
- `InterpolatedStringNode` - 式展開を含む文字列
- `RegexpNode` - 正規表現
- `InterpolatedRegexpNode` - 式展開を含む正規表現
- `RangeNode` - 範囲
- `ArrayNode` - 配列
- `HashNode` - ハッシュ
- `LambdaNode` - ラムダ

これらのノードは、対応する型オブジェクトを生成します。

### 7. 変数ノード (variable.rb)

変数の読み書きを表現するノード群：

- `LocalVariableReadNode` - ローカル変数の読み取り
- `LocalVariableWriteNode` - ローカル変数の書き込み
- `InstanceVariableReadNode` - インスタンス変数の読み取り
- `InstanceVariableWriteNode` - インスタンス変数の書き込み
- `GlobalVariableReadNode` - グローバル変数の読み取り
- `GlobalVariableWriteNode` - グローバル変数の書き込み
- `ClassVariableReadNode` - クラス変数の読み取り
- `ClassVariableWriteNode` - クラス変数の書き込み
- `RegexpReferenceReadNode` - 正規表現の特殊変数の読み取り

これらのノードは、変数のスコープと型を管理します。

## 型解析の流れ

1. **定義フェーズ** (`define`メソッド)
   - 各ノードが静的な定義を行う
   - メソッド、クラス、定数などの定義を登録

2. **インストールフェーズ** (`install`メソッド)
   - 各ノードを型グラフにインストール
   - 型の流れを表すエッジを作成
   - 型推論のための制約を設定

3. **差分計算** (`diff`メソッド)
   - 前回の解析結果との差分を計算
   - 変更があったノードのみを再解析

4. **型の伝播**
   - 型グラフを通じて型情報が伝播
   - 制約に基づいて型が推論される

## 特徴的な機能

### 1. 型フィルター

制御フローに基づいて型を絞り込む機能：
- `NilFilter` - nilチェックによる型の絞り込み
- `IsAFilter` - is_a?チェックによる型の絞り込み
- `BotFilter` - 到達不能コードの検出

### 2. 変更セット (ChangeSet)

型グラフへの変更を管理する仕組み：
- エッジの追加・削除
- ボックス（操作）の追加・削除
- 診断情報の管理

### 3. RBSコメントのサポート

メソッド定義の直前にRBSコメントを記述することで、型注釈を提供できます：

```ruby
#: (Integer) -> String
def foo(x)
  x.to_s
end
```

### 4. パターンマッチングのサポート

Ruby 2.7以降のパターンマッチング構文に対応し、パターンに基づく型の絞り込みを行います。

## まとめ

TypeProfのコアASTモジュールは、Rubyコードの構造を型解析に適した形で表現し、効率的な型推論を可能にします。各ノードは型グラフの一部として機能し、型情報の伝播と制約の解決に貢献します。このモジュールは、TypeProfの型解析エンジンの中核を担っています。
