# Boxシステム

Boxシステムは、TypeProfの型推論エンジンの中核をなす部分で、型の流れと変更を追跡するためのメカニズムを提供します。

## 概要

Boxシステムは、[lib/typeprof/core/graph/box.rb](../../lib/typeprof/core/graph/box.rb)で定義されています。Boxは、メソッド呼び出し、変数代入、リターン文などの操作を表現し、これらの操作に関連する型の流れをモデル化します。

## 基本構造

すべてのBoxは`Box`基底クラスを継承しています：

[lib/typeprof/core/graph/box.rb](../../lib/typeprof/core/graph/box.rb)

各Boxには以下の主要コンポーネントがあります：
- `node`: 関連するASTノード
- `changes`: 型の変更を追跡するためのChangeSet
- `run`メソッド: Boxの処理を実行するメソッド

## 主なBoxの種類

TypeProfには、様々な種類のBoxが定義されています：

### MethodCallBox

メソッド呼び出しを表現します：

このBoxは、レシーバ、メソッド名、引数、および戻り値を追跡します。

### MethodDefBox

メソッド定義を表現します：

このBoxは、メソッドの定義を記録し、その引数と戻り値の型を追跡します。

### EscapeBox

値の「エスケープ」（ある場所から別の場所への型の流れ）を表現します：

### 変数操作Box

変数の読み取りと書き込みを表現するBoxもあります：
- `LocalVariableReadBox`: ローカル変数の読み取り
- `LocalVariableWriteBox`: ローカル変数の書き込み
- `InstanceVariableReadBox`: インスタンス変数の読み取り
- `ClassVariableReadBox`: クラス変数の読み取り

## Box実行のメカニズム

Boxの実行は、`run`メソッドによって処理されます：

このメソッドは、Boxの具体的な処理を行う`run0`メソッドを呼び出し、その結果を`changes`に記録します。

例えば、`MethodCallBox`の`run0`メソッドは、メソッド呼び出しを解決し、適切な型の流れを設定します：

## メソッド解決のプロセス

`MethodCallBox`では、`resolve`メソッドを使用してメソッド呼び出しを解決します：

このメソッドは、レシーバの型に基づいてメソッドを検索し、適切なメソッド定義を見つけます。

## 型の変更追跡

型の変更は、`ChangeSet`クラスによって追跡されます（[lib/typeprof/core/graph/change_set.rb](../../lib/typeprof/core/graph/change_set.rb)）。`ChangeSet`は、型の追加や削除などの変更を記録し、必要に応じて再実行できるようにします。

## Boxシステムの重要性

Boxシステムは、TypeProfの型推論エンジンの中核であり、以下の役割を果たします：

1. **型の流れのモデル化**: コード内での型の流れを正確にモデル化します
2. **メソッド解決**: 動的ディスパッチをシミュレートしてメソッド呼び出しを解決します
3. **変更追跡**: 型の変更を追跡し、変更があった場合に関連するBoxを再実行します
4. **診断情報**: 型エラーや警告を生成します

Boxシステムの詳細な理解は、TypeProfの型推論メカニズムを理解する上で不可欠です。

## 実装の詳細

### Box作成のメカニズム

Boxは、AST（抽象構文木）ノードの`install0`メソッド内で作成されます：

```ruby
def install0
  box = SomeBox.new(@node, ...)
  @env.add_box(box)
  # ...
end
```

### Box実行のフロー

Boxの実行は、以下のようなフローで行われます：

1. `GlobalEnv`がBoxの実行を管理
2. 各Boxが`run`メソッドを呼び出される
3. `run`メソッドが`run0`メソッドを呼び出し、結果を`changes`に記録
4. 変更があれば、関連するBoxが再実行される

### ChangeSetの詳細

`ChangeSet`クラスは、型の変更を追跡し、必要に応じてBoxを再実行するための情報を提供します：

[lib/typeprof/core/graph/change_set.rb](../../lib/typeprof/core/graph/change_set.rb)

`ChangeSet`は、以下の情報を追跡します：
- 新しい型の追加
- 型の削除
- 型の変更
- 依存関係の追加/削除

## デバッグ方法

Boxシステムをデバッグするための方法：

### Boxの状態の表示

```ruby
def debug_box(box)
  puts "Box type: #{box.class}"
  puts "Box state: #{box.instance_variables}"
  # その他の詳細情報
end
```

### 型の流れの追跡

```ruby
vtx = some_vertex
puts "Types in vertex:"
vtx.each_type do |ty|
  puts "  #{ty.show}"
end
```

### 変更の追跡

```ruby
changes = TypeProf::Core::Graph::ChangeSet.new
# 何らかの操作を実行
puts "Changes:"
changes.each_add do |vtx, ty|
  puts "  Added #{ty.show} to #{vtx.object_id}"
end
```

## カスタムBoxの追加方法

TypeProfに新しいBox型を追加するには、以下の手順に従います：

1. `Box`クラスを継承した新しいBoxクラスを定義
2. `run0`メソッドを実装して、Boxの処理を定義
3. 適切なASTノードの`install0`メソッド内で新しいBoxを作成

```ruby
class CustomBox < Box
  def initialize(node, input_vtx, output_vtx)
    super(node)
    @input_vtx = input_vtx
    @output_vtx = output_vtx
  end

  def run0(changes)
    # Boxの処理ロジック
    @input_vtx.each_type do |ty|
      # 何らかの処理
      changes.add_type(@output_vtx, result_ty)
    end
  end
end
```

## 高度な使用例

### メソッド呼び出しの解決

メソッド呼び出しの解決は、`MethodCallBox`の`resolve`メソッドで行われます：

[lib/typeprof/core/graph/box.rb](../../lib/typeprof/core/graph/box.rb)

このメソッドは、レシーバの型に基づいてメソッドを検索し、適切なメソッド定義を見つけます。

### フィルタの適用

型のフィルタリングは、条件分岐などで型の制約を追加する際に使用されます：

```ruby
filter = TypeProf::Core::Graph::IsAFilter.new(genv.get_module([:String]), true)
filtered_vtx = filter.filter(original_vtx, changes)
```

### エスケープメカニズム

Boxシステムには、値の「エスケープ」（ある場所から別の場所への型の流れ）を表現するための`EscapeBox`があります：

[lib/typeprof/core/graph/box.rb](../../lib/typeprof/core/graph/box.rb)

このBoxは、メソッド間の値の受け渡しなど、異なるスコープ間での型の流れを管理するために使用されます。
