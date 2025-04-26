# 型システム

TypeProfの型システムは、Rubyコードの型を表現し、型の互換性をチェックするための基盤を提供します。

## 概要

TypeProfの型システムは、[lib/typeprof/core/type.rb](../../lib/typeprof/core/type.rb) で定義されています。このファイルには、異なる種類の型を表現するためのクラスが含まれています。

## 型の表現

TypeProfでは、以下のような型クラスが定義されています：

主な型クラス：
- `Type::Singleton`: クラスやモジュールのシングルトン型（クラスメソッドのレシーバ）
- `Type::Instance`: クラスやモジュールのインスタンス型（インスタンスメソッドのレシーバ）
- `Type::Array`: 配列型
- `Type::Hash`: ハッシュ型
- `Type::Proc`: Procオブジェクト型
- `Type::Symbol`: シンボル型
- `Type::Bot`: 最下位型（nil, false, true の共通型）

## 型の互換性チェック

型の互換性は、各型クラスの `check_match` メソッドでチェックされます。例えば、`Instance`型の互換性チェックは以下のように実装されています：

このメソッドは、2つの型が互換性があるかどうかを判断します。型の互換性は、型の階層構造（継承関係）およびジェネリック型パラメータの互換性に基づいて決定されます。

## 型のメモ化

TypeProfでは、型オブジェクトの作成をメモ化して効率化しています：

このメソッドにより、同じパラメータで型を作成する場合に既存のオブジェクトを再利用することができます。

## 型の表示

型オブジェクトは、`show`メソッドを通じて文字列表現に変換されます：

この文字列表現は、RBS形式の型シグネチャの生成に使用されます。

## 型パラメータのマッピング

型パラメータのマッピングは、`default_param_map`メソッドで処理されます：

このメソッドは、型環境内での型パラメータのマッピングを設定します。

## 特殊な型の処理

TypeProfは、特定の型に対して特別な処理を行います：

- `nil`型は`NilClass`のインスタンスとして表現
- `true`型は`TrueClass`のインスタンスとして表現
- `false`型は`FalseClass`のインスタンスとして表現

これらは表示時に特別に処理されます。

## まとめ

TypeProfの型システムは、Rubyのさまざまな型を表現し、型の互換性をチェックするための強力な基盤を提供しています。このシステムにより、型アノテーションなしでもRubyコードの型を正確に推論することが可能になっています。

## 高度な型の機能

### 型パラメータ

TypeProfは、ジェネリック型パラメータをサポートしています：

型パラメータは、以下のように使用されます：

```ruby
# Array[Integer]のような型の表現
elem_vtx = Source.new(genv.int_type)
array_type = Type::Array.new(genv, [elem_vtx], genv.gen_ary_type(elem_vtx))
```

### 型の互換性チェックの詳細

型の互換性チェックは、型階層とジェネリックパラメータの互換性に基づいて行われます：

このメカニズムにより、以下のような型の互換性がチェックされます：

- サブクラスとスーパークラス（`Integer`は`Numeric`と互換性がある）
- ジェネリックパラメータ（`Array[Integer]`は`Array[Numeric]`と互換性がある）
- インクルードされたモジュール（`Array`は`Enumerable`と互換性がある）

### 型のシリアライズとデシリアライズ

TypeProfは、型情報をRBSフォーマットでシリアライズし、必要に応じてデシリアライズする機能を提供しています。これにより、型情報を保存して後で使用することが可能になります。

```ruby
# 型のRBS表現を取得
rbs_str = type.show

# RBS表現から型を復元
# （実際にはもっと複雑なプロセスが必要）
```

## 型システムのデバッグ方法

型システムをデバッグするための方法：

### 型の表示

```ruby
p type.show  # RBS形式の型表現を表示
```

### 型の互換性チェック

```ruby
changes = TypeProf::Core::Graph::ChangeSet.new
if type1.check_match(genv, changes, Source.new(type2))
  puts "型は互換性があります"
else
  puts "型は互換性がありません"
end
```

## 型システムの拡張方法

TypeProfの型システムを拡張するには、以下の手順に従います：

1. 新しい型クラスを`Type`クラスのサブクラスとして定義
2. 必要なメソッド（`base_type`, `check_match`, `show`など）を実装
3. 型テーブルに新しい型を登録する機能を`GlobalEnv`に追加

```ruby
class CustomType < Type
  def initialize(genv, param)
    @param = param
  end

  def base_type(genv)
    # ベース型を返す
  end

  def check_match(genv, changes, vtx)
    # 型の互換性をチェック
  end

  def show
    # RBS形式の表現を返す
  end
end
```

そして、`GlobalEnv`に新しい型を作成するヘルパーメソッドを追加します：

```ruby
class GlobalEnv
  # 既存のコード...

  def custom_type(param)
    CustomType.new(self, param)
  end
end
```
