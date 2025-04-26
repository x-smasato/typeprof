# 抽象値

TypeProfは、Rubyプログラムを型レベルで抽象的に実行するために、様々な抽象値を使用します。このドキュメントでは、TypeProfが扱う抽象値の種類と特性について説明します。

## 抽象値の概要

抽象値は、Rubyプログラムの実行中に現れる可能性のある値を型レベルで表現したものです。TypeProfでは、これらの抽象値を使用して型推論を行います。

抽象値は、<ref_file file="lib/typeprof/core/type.rb" />で定義されています。

## 基本的な抽象値

### クラスのインスタンス

クラスのインスタンスは、`Type::Instance`クラスで表現されます：

<ref_snippet file="lib/typeprof/core/type.rb" lines="76-89" />

例えば、`String`クラスのインスタンスは以下のように表現されます：

```ruby
Type::Instance.new(genv, genv.resolve_cpath([:String]), [])
```

### クラスオブジェクト

クラスオブジェクト（シングルトン）は、`Type::Singleton`クラスで表現されます：

<ref_snippet file="lib/typeprof/core/type.rb" lines="29-38" />

例えば、`String`クラスオブジェクトは以下のように表現されます：

```ruby
Type::Singleton.new(genv, genv.resolve_cpath([:String]))
```

### 特殊な値

特殊な値（`nil`, `true`, `false`）は、それぞれのクラスのインスタンスとして表現されます：

<ref_snippet file="lib/typeprof/core/type.rb" lines="146-151" />

## コンテナクラスのインスタンス

TypeProfでは、配列やハッシュなどのコンテナクラスは、その要素の型情報を保持する特別な抽象値として扱われます。これにより、コンテナ内の要素の型を追跡し、型安全性を確保することができます。

### 配列

配列は、`Type::Array`クラスで表現されます：

<ref_snippet file="lib/typeprof/core/type.rb" lines="156-165" />

配列型は、要素の型情報を保持します：

<ref_snippet file="lib/typeprof/core/type.rb" lines="166-172" />

#### 配列の型表現

TypeProfでは、配列は`Array[T]`という形式でRBS出力されます。ここで、`T`は要素の型です。例えば：

```ruby
# Rubyコード
[1, 2, 3]
["a", "b", "c"]
[1, "a", :foo]

# RBS表現
Array[Integer]
Array[String]
Array[Integer | String | Symbol]
```

#### 均質配列と不均質配列

TypeProfは、均質配列（同じ型の要素を持つ配列）と不均質配列（異なる型の要素を持つ配列）を区別して扱います：

```ruby
# 均質配列
[1, 2, 3]  # => Array[Integer]

# 不均質配列
[1, "a", :foo]  # => Array[Integer | String | Symbol]
```

不均質配列の場合、要素の型はユニオン型として表現されます。

#### 配列操作と型推論

TypeProfは、配列操作に基づいて型を推論します：

```ruby
# 配列の作成
ary = [1, 2, 3]  # => Array[Integer]

# 要素の追加
ary << "str"     # => Array[Integer | String]

# 要素の取得
ary[0]           # => Integer | String
```

#### ネストされた配列

TypeProfは、ネストされた配列の型も追跡できます：

```ruby
# 二次元配列
[[1, 2], [3, 4]]  # => Array[Array[Integer]]

# 異なる型の要素を持つネストされた配列
[[1, 2], ["a", "b"]]  # => Array[Array[Integer] | Array[String]]
```

内部的な表現例：

```ruby
elem_vtx = Source.new(genv.int_type)
inner_ary_type = Type::Array.new(genv, [elem_vtx], genv.gen_ary_type(elem_vtx))
inner_vtx = Source.new(inner_ary_type)
Type::Array.new(genv, [inner_vtx], genv.gen_ary_type(inner_vtx))
```

### ハッシュ

ハッシュは、`Type::Hash`クラスで表現されます：

<ref_snippet file="lib/typeprof/core/type.rb" lines="234-240" />

ハッシュ型は、キーと値の型情報を保持します：

<ref_snippet file="lib/typeprof/core/type.rb" lines="242-248" />

#### ハッシュの型表現

TypeProfでは、ハッシュは`Hash[K, V]`という形式でRBS出力されます。ここで、`K`はキーの型、`V`は値の型です。例えば：

```ruby
# Rubyコード
{a: 1, b: 2}
{"a" => 1, "b" => 2}
{a: 1, b: "str"}

# RBS表現
Hash[Symbol, Integer]
Hash[String, Integer]
Hash[Symbol, Integer | String]
```

#### キーと値の型

TypeProfは、ハッシュのキーと値の型を個別に追跡します：

```ruby
# シンボルキーと整数値
h = {a: 1, b: 2}  # => Hash[Symbol, Integer]

# 文字列キーと整数値
h = {"a" => 1, "b" => 2}  # => Hash[String, Integer]

# 混合値型
h = {a: 1, b: "str"}  # => Hash[Symbol, Integer | String]
```

#### ハッシュ操作と型推論

TypeProfは、ハッシュ操作に基づいて型を推論します：

```ruby
# ハッシュの作成
h = {a: 1, b: 2}  # => Hash[Symbol, Integer]

# 要素の追加
h[:c] = "str"     # => Hash[Symbol, Integer | String]

# 要素の取得
h[:a]             # => Integer | String
```

#### ネストされたハッシュ

TypeProfは、ネストされたハッシュの型も追跡できます：

```ruby
# ネストされたハッシュ
{a: {x: 1, y: 2}, b: {z: 3}}  # => Hash[Symbol, Hash[Symbol, Integer]]
```

内部的な表現例：

```ruby
key_vtx = Source.new(genv.sym_type)
val_vtx = Source.new(genv.int_type)
inner_hash_type = Type::Hash.new(genv, {}, genv.gen_hash_type(key_vtx, val_vtx))
inner_vtx = Source.new(inner_hash_type)
Type::Hash.new(genv, {}, genv.gen_hash_type(key_vtx, inner_vtx))
```

### 範囲

範囲は、`Type::Range`クラスで表現されます（このクラスは明示的には定義されていませんが、`gen_range_type`メソッドを通じて生成されます）：

<ref_snippet file="lib/typeprof/core/env.rb" lines="55-61" />

#### 範囲の型表現

TypeProfでは、範囲は`Range[T]`という形式でRBS出力されます。ここで、`T`は要素の型です。例えば：

```ruby
# Rubyコード
(1..10)
("a".."z")

# RBS表現
Range[Integer]
Range[String]
```

#### 範囲操作と型推論

TypeProfは、範囲操作に基づいて型を推論します：

```ruby
# 範囲の作成
r = (1..10)  # => Range[Integer]

# 範囲の変換
r.to_a       # => Array[Integer]
```

内部的な表現例：

```ruby
elem_vtx = Source.new(genv.int_type)
genv.gen_range_type(elem_vtx)
```

### Enumerator

Enumeratorは、反復処理を抽象化するためのクラスです。TypeProfでは、Enumeratorの要素の型を追跡します：

```ruby
# Rubyコード
[1, 2, 3].each
"abc".each_char

# RBS表現
Enumerator[Integer]
Enumerator[String]
```

内部的な表現例：

```ruby
elem_vtx = Source.new(genv.int_type)
genv.gen_enumerator_type(elem_vtx)
```

## Procオブジェクト

Procオブジェクトは、`Type::Proc`クラスで表現されます：

<ref_snippet file="lib/typeprof/core/type.rb" lines="264-282" />

Proc型は、ブロックの情報を保持します：

```ruby
block = RecordBlock.new(node)
Type::Proc.new(genv, block)
```

Procオブジェクトは、メソッド呼び出しにブロックを渡す際や、ブロックを値として扱う際に使用されます。

## シンボル

シンボルは、`Type::Symbol`クラスで表現されます：

<ref_snippet file="lib/typeprof/core/type.rb" lines="284-311" />

例えば、`:foo`シンボルは以下のように表現されます：

```ruby
Type::Symbol.new(genv, :foo)
```

## 特殊な型

### Bot型

Bot型（最下位型）は、`Type::Bot`クラスで表現されます：

<ref_snippet file="lib/typeprof/core/type.rb" lines="313-328" />

Bot型は、型の階層構造の最下位に位置し、すべての型と互換性があります。

### 型変数

型変数は、`Type::Var`クラスで表現されます：

<ref_snippet file="lib/typeprof/core/type.rb" lines="330-350" />

型変数は、ジェネリック型パラメータなどで使用されます。

## 抽象値の互換性チェック

抽象値間の互換性は、各型クラスの`check_match`メソッドでチェックされます。例えば、`Instance`型の互換性チェックは以下のように実装されています：

<ref_snippet file="lib/typeprof/core/type.rb" lines="91-118" />

このメソッドは、2つの型が互換性があるかどうかを判断します。型の互換性は、型の階層構造（継承関係）およびジェネリック型パラメータの互換性に基づいて決定されます。

## 抽象値の表示

抽象値は、`show`メソッドを通じて文字列表現に変換されます：

<ref_snippet file="lib/typeprof/core/type.rb" lines="145-153" />
<ref_snippet file="lib/typeprof/core/type.rb" lines="225-231" />

この文字列表現は、RBS形式の型シグネチャの生成に使用されます。

## 抽象値の重要性

抽象値は、TypeProfの型推論の基盤となるものであり、以下の役割を果たします：

1. **型の表現**: Rubyプログラムの値を型レベルで表現
2. **型の互換性チェック**: 型の互換性を判断
3. **型の流れのモデル化**: プログラム内での型の流れをモデル化
4. **型シグネチャの生成**: RBS形式の型シグネチャを生成

抽象値の理解は、TypeProfの型推論メカニズムを深く理解するために不可欠です。
