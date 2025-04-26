# 型システム

TypeProfの型システムは、Rubyコードの型を表現し、型の互換性をチェックするための基盤を提供します。

## 概要

TypeProfの型システムは、<ref_file file="lib/typeprof/core/type.rb" /> で定義されています。このファイルには、異なる種類の型を表現するためのクラスが含まれています。

## 型の表現

TypeProfでは、以下のような型クラスが定義されています：

<ref_snippet file="lib/typeprof/core/type.rb" lines="29-69" />
<ref_snippet file="lib/typeprof/core/type.rb" lines="76-154" />

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

<ref_snippet file="lib/typeprof/core/type.rb" lines="91-118" />

このメソッドは、2つの型が互換性があるかどうかを判断します。型の互換性は、型の階層構造（継承関係）およびジェネリック型パラメータの互換性に基づいて決定されます。

## 型のメモ化

TypeProfでは、型オブジェクトの作成をメモ化して効率化しています：

<ref_snippet file="lib/typeprof/core/type.rb" lines="3-7" />

このメソッドにより、同じパラメータで型を作成する場合に既存のオブジェクトを再利用することができます。

## 型の表示

型オブジェクトは、`show`メソッドを通じて文字列表現に変換されます：

<ref_snippet file="lib/typeprof/core/type.rb" lines="145-153" />
<ref_snippet file="lib/typeprof/core/type.rb" lines="225-231" />

この文字列表現は、RBS形式の型シグネチャの生成に使用されます。

## 型パラメータのマッピング

型パラメータのマッピングは、`default_param_map`メソッドで処理されます：

<ref_snippet file="lib/typeprof/core/type.rb" lines="18-27" />

このメソッドは、型環境内での型パラメータのマッピングを設定します。

## 特殊な型の処理

TypeProfは、特定の型に対して特別な処理を行います：

- `nil`型は`NilClass`のインスタンスとして表現
- `true`型は`TrueClass`のインスタンスとして表現
- `false`型は`FalseClass`のインスタンスとして表現

これらは表示時に特別に処理されます：

<ref_snippet file="lib/typeprof/core/type.rb" lines="146-151" />

## まとめ

TypeProfの型システムは、Rubyのさまざまな型を表現し、型の互換性をチェックするための強力な基盤を提供しています。このシステムにより、型アノテーションなしでもRubyコードの型を正確に推論することが可能になっています。
