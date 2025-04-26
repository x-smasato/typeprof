# 環境システム

環境システムは、TypeProfの型推論に必要なコンテキスト情報を管理するためのコンポーネントです。

## 概要

環境システムは主に以下のファイルで定義されています：
- [lib/typeprof/core/env.rb](../../lib/typeprof/core/env.rb)
- [lib/typeprof/core/env/method.rb](../../lib/typeprof/core/env/method.rb)
- [lib/typeprof/core/env/method_entity.rb](../../lib/typeprof/core/env/method_entity.rb)
- [lib/typeprof/core/env/module_entity.rb](../../lib/typeprof/core/env/module_entity.rb)

このシステムは、クラス・モジュール定義、メソッド定義、変数定義などの情報を管理し、型推論プロセスに提供します。

## グローバル環境（GlobalEnv）

`GlobalEnv`クラスは、TypeProfの型推論に関するグローバルな状態を管理します：

[lib/typeprof/core/env.rb](../../lib/typeprof/core/env.rb)

主な役割：
- 型テーブルの管理
- モジュールとクラスの階層構造の管理
- メソッド定義の管理
- グローバル変数、インスタンス変数、クラス変数の管理
- 型エイリアスの管理

### 基本型の初期化

`GlobalEnv`は、Rubyの基本型（Object, Class, Module, Nilなど）を初期化します：

### 継承とインクルードの処理

`GlobalEnv`は、クラスの継承関係とモジュールのインクルードを処理するメソッドを提供します：

### 型推論の実行管理

`GlobalEnv`は、型推論の実行キューを管理します：

## ローカル環境（LocalEnv）

`LocalEnv`クラスは、メソッドやブロックなどのローカルスコープのコンテキスト情報を管理します：

主な役割：
- パス情報の管理
- コンテキスト参照（CRef）の管理
- ローカル変数の管理
- リターンボックスの管理
- フィルタの管理

### 変数管理

`LocalEnv`は、ローカル変数の管理のためのメソッドを提供します：

### フィルタの処理

`LocalEnv`は、型のフィルタリングをサポートしています：

## コンテキスト参照（CRef）

`CRef`クラスは、スコープのコンテキスト情報を表現します：

主な役割：
- クラスパスの管理
- スコープレベル（インスタンス/クラス）の管理
- メソッドIDの管理
- 外部コンテキストの参照

### selfの解決

`CRef`は、現在のスコープでの`self`の型を解決するメソッドを提供します：

## エンティティクラス

環境システムには、様々なエンティティを表現するためのクラスも含まれています：

- `ModuleEntity`: モジュール/クラスを表現
- `MethodEntity`: メソッドを表現
- `ValueEntity`: 値（変数など）を表現
- `TypeAliasEntity`: 型エイリアスを表現

これらのエンティティは、型推論プロセスで使用される詳細な情報を提供します。

## 環境システムの重要性

環境システムは、TypeProfの型推論において以下の役割を果たします：

1. **コンテキスト情報の提供**: スコープやクラス階層などのコンテキスト情報を提供
2. **名前解決**: 変数、メソッド、定数などの名前解決をサポート
3. **型情報の管理**: 型テーブルや型エイリアスなどの型情報を管理
4. **実行管理**: 型推論の実行順序と依存関係を管理

環境システムの理解は、TypeProfの型推論メカニズムを深く理解するために重要です。

## 実践的な使用例

### グローバル環境の作成

```ruby
genv = TypeProf::Core::GlobalEnv.new
```

### モジュール/クラスの定義

```ruby
mod = genv.get_module([:Foo])
cls = genv.get_class([:Foo, :Bar], mod)
```

### メソッドの定義

```ruby
mid = :hello
args = FormalArguments.new([[:req, :x]], nil, nil, nil, {}, nil, nil)
entity = genv.get_method_entity(cls, mid, false)
entity.add_def(args, block)
```

## エンティティ間の関係

環境システムのエンティティ間の関係は以下の通りです：

1. `GlobalEnv`は複数の`ModuleEntity`を管理
2. 各`ModuleEntity`は複数の`MethodEntity`と内部モジュールを管理
3. 各`MethodEntity`は複数のメソッド定義を管理

以下の図は、エンティティ間の関係を示しています：

```
GlobalEnv
  ├── ModuleEntity (Object)
  │     ├── MethodEntity (initialize)
  │     ├── MethodEntity (to_s)
  │     └── ...
  ├── ModuleEntity (String)
  │     ├── MethodEntity (to_sym)
  │     └── ...
  └── ...
```

## CRefの詳細な使用方法

CRefは、スコープのコンテキスト情報を表現し、以下のように使用します：

```ruby
cref = CRef.new([:Foo, :Bar], :instance, nil)
self_type = cref.get_self_type(genv)
```

CRefは、スコープの階層構造を表現するための重要な要素です。例えば、クラスメソッドのスコープとインスタンスメソッドのスコープを区別するために使用されます。

### CRefの使用例

```ruby
# クラススコープのCRef
class_cref = CRef.new([:Foo], :class, nil)

# インスタンススコープのCRef
instance_cref = CRef.new([:Foo], :instance, nil)

# メソッドスコープのCRef
method_cref = CRef.new([:Foo], :instance, :bar)
```

## フィルタの詳細

環境システムでは、型のフィルタリングを行うためのフィルタが提供されています：

- `NilFilter`：nilかどうかでフィルタリング
- `IsAFilter`：特定のクラスのインスタンスかどうかでフィルタリング
- `TrueFilter`/`FalseFilter`：真偽値でフィルタリング

[lib/typeprof/core/graph/filter.rb](../../lib/typeprof/core/graph/filter.rb)

フィルタの使用例：

```ruby
filter = TypeProf::Core::Graph::NilFilter.new(true)  # nilの場合にマッチ
result = filter.filter(vtx, changes)
```

### フィルタの組み合わせ

複数のフィルタを組み合わせることで、より複雑な条件でのフィルタリングが可能です：

```ruby
# nilまたはStringのインスタンスの場合にマッチ
nil_filter = TypeProf::Core::Graph::NilFilter.new(true)
string_filter = TypeProf::Core::Graph::IsAFilter.new(genv.resolve_cpath([:String]), true)
combined_result = nil_filter.filter(vtx, changes) || string_filter.filter(vtx, changes)
```

## 環境システムの拡張方法

環境システムを拡張するには、以下の方法があります：

1. 新しい型のエンティティを追加
2. 既存のエンティティに新しい機能を追加
3. フィルタシステムの拡張

### 新しいエンティティの追加

```ruby
module TypeProf::Core
  class CustomEntity
    def initialize(genv)
      @genv = genv
      # 初期化処理
    end

    # エンティティのメソッド
  end
end
```

### フィルタシステムの拡張

例えば、新しいフィルタを追加するには：

```ruby
module TypeProf::Core::Graph
  class CustomFilter < Filter
    def initialize(positive)
      @positive = positive
    end

    def filter(vtx, changes)
      # フィルタリングロジック
    end
  end
end
```

### GlobalEnvの拡張

`GlobalEnv`クラスを拡張して、新しい機能を追加することもできます：

```ruby
module TypeProf::Core
  class GlobalEnv
    # 既存のコード...

    def custom_method
      # 新しい機能
    end
  end
end
```

環境システムの拡張は、TypeProfの機能を拡張するための重要な手段です。適切に拡張することで、より高度な型推論や特殊なケースの処理が可能になります。
