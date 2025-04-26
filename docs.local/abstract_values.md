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

### 配列

配列は、`Type::Array`クラスで表現されます：

<ref_snippet file="lib/typeprof/core/type.rb" lines="156-165" />

配列型は、要素の型情報を保持します：

<ref_snippet file="lib/typeprof/core/type.rb" lines="166-172" />

例えば、整数の配列は以下のように表現されます：

```ruby
elem_vtx = Source.new(genv.int_type)
Type::Array.new(genv, [elem_vtx], genv.gen_ary_type(elem_vtx))
```

### ハッシュ

ハッシュは、`Type::Hash`クラスで表現されます：

<ref_snippet file="lib/typeprof/core/type.rb" lines="234-240" />

ハッシュ型は、キーと値の型情報を保持します：

<ref_snippet file="lib/typeprof/core/type.rb" lines="242-248" />

例えば、文字列をキー、整数を値とするハッシュは以下のように表現されます：

```ruby
key_vtx = Source.new(genv.str_type)
val_vtx = Source.new(genv.int_type)
Type::Hash.new(genv, {}, genv.gen_hash_type(key_vtx, val_vtx))
```

### 範囲

範囲は、`Type::Range`クラスで表現されます（このクラスは明示的には定義されていませんが、`gen_range_type`メソッドを通じて生成されます）：

<ref_snippet file="lib/typeprof/core/env.rb" lines="55-61" />

例えば、整数の範囲は以下のように表現されます：

```ruby
elem_vtx = Source.new(genv.int_type)
genv.gen_range_type(elem_vtx)
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
