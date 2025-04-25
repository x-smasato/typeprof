# TypeProf CLI

TypeProfのコマンドラインインターフェース（CLI）モジュールは、TypeProfの静的型解析機能をコマンドラインから利用するための機能を提供します。

## 概要

CLIモジュールは`TypeProf::CLI::CLI`クラスを中心に実装されており、以下の機能を提供します：

- コマンドライン引数の解析
- 解析対象ファイルの検索
- 型解析の実行と結果の出力
- Language Server Protocol (LSP) モードの起動

## 初期化と設定

CLIクラスは、コマンドライン引数を解析し、設定オプションを初期化します。

```ruby
cli = TypeProf::CLI::CLI.new(ARGV)
cli.run
```

### 設定オプションの種類

CLIクラスは3種類の設定オプションを管理します：

1. **core_options**: 型解析エンジン自体の動作を制御するオプション
2. **lsp_options**: LSPサーバーの動作を制御するオプション
3. **cli_options**: コマンドライン実行に関連するオプション

## コマンドラインオプション

TypeProfは以下のコマンドラインオプションをサポートしています：

### 基本オプション

- `-o OUTFILE`: 標準出力の代わりに指定したファイルに出力
- `-q, --quiet`: 静かモード（進捗インジケータを表示しない）
- `-v, --verbose`: 詳細モード（エラーを表示する）
- `--version`: TypeProfのバージョンを表示
- `--collection PATH`: コレクション設定のファイルパスを指定
- `--no-collection`: コレクション設定を無視
- `--lsp`: LSPサーバーモードで起動

### 解析出力オプション

- `--[no-]show-typeprof-version`: ヘッダーにTypeProfのバージョンを表示するかどうか
- `--[no-]show-errors`: 解析中に見つかった可能性のあるエラーを表示するかどうか
- `--[no-]show-parameter-names`: メソッドのパラメータ名を表示するかどうか
- `--[no-]show-source-locations`: メソッド定義の元のソース位置を表示するかどうか

### 高度なオプション

- `--[no-]stackprof MODE`: stackprofを有効にする（デバッグ目的、MODE: cpu/wall/object）

### LSPオプション

- `--port PORT`: リクエストを待ち受けるポート番号を指定
- `--stdio`: LSP通信に標準入出力を使用

## 実行モード

CLIクラスは2つの実行モードをサポートしています：

### 1. CLIモード（通常モード）

通常のコマンドラインモードでは、指定されたファイルを解析してRBS形式の型情報を出力します。

```ruby
def run_cli
  # TypeProf::Core::Service インスタンスを作成
  core = TypeProf::Core::Service.new(@core_options)
  
  # バージョン情報表示（--version オプション指定時）
  puts "typeprof #{ TypeProf::VERSION }" if @cli_options[:display_version]
  
  # 解析対象ファイルを検索
  files = find_files
  
  # プロファイラ設定（オプション指定時）
  set_profiler do
    # ファイルをバッチ処理で解析
    core.batch(files, @cli_options[:output])
    # 出力ストリームを閉じる
    output.close
  end
end
```

### 2. LSPモード

Language Server Protocol (LSP) モードでは、統合開発環境（IDE）やテキストエディタと連携して、リアルタイムの型解析とコード補完を提供します。

```ruby
def run_lsp
  if @lsp_options[:stdio]
    # 標準入出力を使用してLSPサーバーを起動
    TypeProf::LSP::Server.start_stdio(@core_options)
  else
    # ソケットを使用してLSPサーバーを起動
    TypeProf::LSP::Server.start_socket(@core_options)
  end
end
```

## ファイル検索機能

CLIクラスは、コマンドライン引数で指定されたパスからRubyファイル（`.rb`）とRBS型定義ファイル（`.rbs`）を検索します。

```ruby
def find_files
  files = []
  @cli_options[:argv].each do |path|
    if File.directory?(path)
      # ディレクトリが指定された場合は再帰的に検索
      files.concat(Dir.glob("#{ path }/**/*.{rb,rbs}"))
    elsif File.file?(path)
      # ファイルが指定された場合はそのファイルを追加
      files << path
    else
      # 存在しないパスが指定された場合はエラー
      raise OptionParser::InvalidOption.new("no such file or directory -- #{ path }")
    end
  end
  
  # 入力ファイルがない場合はエラー（--versionオプションのみの場合を除く）
  if files.empty?
    exit if @cli_options[:display_version]
    raise OptionParser::InvalidOption.new("no input files")
  end
  
  files
end
```

## RBS コレクション設定

TypeProfは、RBSコレクションの設定ファイルをサポートしています。これにより、サードパーティライブラリの型定義を利用することができます。

```ruby
def setup_rbs_collection(path)
  return nil if path == :no
  
  unless path
    path = RBS::Collection::Config::PATH.exist? ? RBS::Collection::Config::PATH.to_s : nil
    return nil unless path
  end
  
  if !File.readable?(path)
    raise OptionParser::InvalidOption.new("file not found: #{ path }")
  end
  
  lock_path = RBS::Collection::Config.to_lockfile_path(Pathname(path))
  if !File.readable?(lock_path)
    raise OptionParser::InvalidOption.new("file not found: #{ lock_path.to_s }; please run 'rbs collection install")
  end
  
  RBS::Collection::Config::Lockfile.from_lockfile(lockfile_path: lock_path, data: YAML.load_file(lock_path))
end
```

## プロファイリング機能

TypeProfは、stackprofを使用したプロファイリング機能をサポートしています（デバッグ目的）。

```ruby
def set_profiler
  if @cli_options[:stackprof]
    require "stackprof"
    out = "typeprof-stackprof-#{ @cli_options[:stackprof] }.dump"
    StackProf.start(mode: @cli_options[:stackprof], out: out, raw: true)
  end
  
  yield
  
ensure
  if @cli_options[:stackprof] && defined?(StackProf)
    StackProf.stop
    StackProf.results
  end
end
```
