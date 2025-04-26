# 環境システム

環境システムは、TypeProfの型推論に必要なコンテキスト情報を管理するためのコンポーネントです。

## 概要

環境システムは主に以下のファイルで定義されています：
- <ref_file file="lib/typeprof/core/env.rb" />
- <ref_file file="lib/typeprof/core/env/method.rb" />
- <ref_file file="lib/typeprof/core/env/method_entity.rb" />
- <ref_file file="lib/typeprof/core/env/module_entity.rb" />

このシステムは、クラス・モジュール定義、メソッド定義、変数定義などの情報を管理し、型推論プロセスに提供します。

## グローバル環境（GlobalEnv）

`GlobalEnv`クラスは、TypeProfの型推論に関するグローバルな状態を管理します：

<ref_snippet file="lib/typeprof/core/env.rb" lines="2-42" />

主な役割：
- 型テーブルの管理
- モジュールとクラスの階層構造の管理
- メソッド定義の管理
- グローバル変数、インスタンス変数、クラス変数の管理
- 型エイリアスの管理

### 基本型の初期化

`GlobalEnv`は、Rubyの基本型（Object, Class, Module, Nilなど）を初期化します：

<ref_snippet file="lib/typeprof/core/env.rb" lines="11-39" />

### 継承とインクルードの処理

`GlobalEnv`は、クラスの継承関係とモジュールのインクルードを処理するメソッドを提供します：

<ref_snippet file="lib/typeprof/core/env.rb" lines="65-90" />

### 型推論の実行管理

`GlobalEnv`は、型推論の実行キューを管理します：

<ref_snippet file="lib/typeprof/core/env.rb" lines="162-180" />

## ローカル環境（LocalEnv）

`LocalEnv`クラスは、メソッドやブロックなどのローカルスコープのコンテキスト情報を管理します：

<ref_snippet file="lib/typeprof/core/env.rb" lines="279-292" />

主な役割：
- パス情報の管理
- コンテキスト参照（CRef）の管理
- ローカル変数の管理
- リターンボックスの管理
- フィルタの管理

### 変数管理

`LocalEnv`は、ローカル変数の管理のためのメソッドを提供します：

<ref_snippet file="lib/typeprof/core/env.rb" lines="293-307" />

### フィルタの処理

`LocalEnv`は、型のフィルタリングをサポートしています：

<ref_snippet file="lib/typeprof/core/env.rb" lines="322-338" />

## コンテキスト参照（CRef）

`CRef`クラスは、スコープのコンテキスト情報を表現します：

<ref_snippet file="lib/typeprof/core/env.rb" lines="348-373" />

主な役割：
- クラスパスの管理
- スコープレベル（インスタンス/クラス）の管理
- メソッドIDの管理
- 外部コンテキストの参照

### selfの解決

`CRef`は、現在のスコープでの`self`の型を解決するメソッドを提供します：

<ref_snippet file="lib/typeprof/core/env.rb" lines="358-370" />

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
