# Boxシステム

Boxシステムは、TypeProfの型推論エンジンの中核をなす部分で、型の流れと変更を追跡するためのメカニズムを提供します。

## 概要

Boxシステムは、<ref_file file="lib/typeprof/core/graph/box.rb" />で定義されています。Boxは、メソッド呼び出し、変数代入、リターン文などの操作を表現し、これらの操作に関連する型の流れをモデル化します。

## 基本構造

すべてのBoxは`Box`基底クラスを継承しています：

<ref_snippet file="lib/typeprof/core/graph/box.rb" lines="3-57" />

各Boxには以下の主要コンポーネントがあります：
- `node`: 関連するASTノード
- `changes`: 型の変更を追跡するためのChangeSet
- `run`メソッド: Boxの処理を実行するメソッド

## 主なBoxの種類

TypeProfには、様々な種類のBoxが定義されています：

### MethodCallBox

メソッド呼び出しを表現します：

<ref_snippet file="lib/typeprof/core/graph/box.rb" lines="693-707" />

このBoxは、レシーバ、メソッド名、引数、および戻り値を追跡します。

### MethodDefBox

メソッド定義を表現します：

<ref_snippet file="lib/typeprof/core/graph/box.rb" lines="372-404" />

このBoxは、メソッドの定義を記録し、その引数と戻り値の型を追跡します。

### EscapeBox

値の「エスケープ」（ある場所から別の場所への型の流れ）を表現します：

<ref_snippet file="lib/typeprof/core/graph/box.rb" lines="289-322" />

### 変数操作Box

変数の読み取りと書き込みを表現するBoxもあります：
- `LocalVariableReadBox`: ローカル変数の読み取り
- `LocalVariableWriteBox`: ローカル変数の書き込み
- `InstanceVariableReadBox`: インスタンス変数の読み取り
- `ClassVariableReadBox`: クラス変数の読み取り

## Box実行のメカニズム

Boxの実行は、`run`メソッドによって処理されます：

<ref_snippet file="lib/typeprof/core/graph/box.rb" lines="36-40" />

このメソッドは、Boxの具体的な処理を行う`run0`メソッドを呼び出し、その結果を`changes`に記録します。

例えば、`MethodCallBox`の`run0`メソッドは、メソッド呼び出しを解決し、適切な型の流れを設定します：

<ref_snippet file="lib/typeprof/core/graph/box.rb" lines="711-769" />

## メソッド解決のプロセス

`MethodCallBox`では、`resolve`メソッドを使用してメソッド呼び出しを解決します：

<ref_snippet file="lib/typeprof/core/graph/box.rb" lines="771-816" />

このメソッドは、レシーバの型に基づいてメソッドを検索し、適切なメソッド定義を見つけます。

## 型の変更追跡

型の変更は、`ChangeSet`クラスによって追跡されます（<ref_file file="lib/typeprof/core/graph/change_set.rb" />）。`ChangeSet`は、型の追加や削除などの変更を記録し、必要に応じて再実行できるようにします。

## Boxシステムの重要性

Boxシステムは、TypeProfの型推論エンジンの中核であり、以下の役割を果たします：

1. **型の流れのモデル化**: コード内での型の流れを正確にモデル化します
2. **メソッド解決**: 動的ディスパッチをシミュレートしてメソッド呼び出しを解決します
3. **変更追跡**: 型の変更を追跡し、変更があった場合に関連するBoxを再実行します
4. **診断情報**: 型エラーや警告を生成します

Boxシステムの詳細な理解は、TypeProfの型推論メカニズムを理解する上で不可欠です。
