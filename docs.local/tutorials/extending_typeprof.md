# TypeProfの拡張方法

このドキュメントでは、TypeProfを拡張するための方法について説明します。

## 拡張ポイント

TypeProfは、以下の拡張ポイントを提供しています：

1. 新しい型の追加
2. 新しいASTノードの追加
3. 新しいBoxの追加
4. 新しいフィルタの追加
5. LSP機能の拡張

## 新しい型の追加

TypeProfに新しい型を追加するには、以下の手順に従います：

### 1. 型クラスの定義

`Type`クラスのサブクラスとして、新しい型クラスを定義します：

```ruby
module TypeProf::Core
  class Type
    class CustomType < Type
      def initialize(genv, param)
        @param = param
      end

      def base_type(genv)
        # ベース型を返す
        genv.obj_type
      end

      def check_match(genv, changes, vtx)
        # 型の互換性をチェック
        vtx.each_type do |other_ty|
          case other_ty
          when CustomType
            return true if @param == other_ty.param
          end
        end
        return false
      end

      def show
        # RBS形式の表現を返す
        "Custom[#{ @param }]"
      end

      attr_reader :param
    end
  end
end
```

### 2. GlobalEnvへの追加

`GlobalEnv`クラスに、新しい型を作成するヘルパーメソッドを追加します：

```ruby
class GlobalEnv
  # 既存のコード...

  def custom_type(param)
    Type::CustomType.new(self, param)
  end
end
```

### 3. 型の使用

新しい型を使用するコードを実装します：

```ruby
# 型の作成
custom_ty = genv.custom_type("param")

# 型の使用
vtx = Source.new(custom_ty)
```

## 新しいASTノードの追加

TypeProfに新しいASTノードを追加するには、以下の手順に従います：

### 1. ノードクラスの定義

`Node`クラスのサブクラスとして、新しいノードクラスを定義します：

```ruby
module TypeProf::Core
  class CustomNode < AST::Node
    def initialize(node, env)
      super
      @param = node.param
    end

    def define
      # 静的な型情報を定義
    end

    def install0
      # 型の流れを設定するBoxを作成
      input_vtx = Source.new
      output_vtx = Source.new
      box = CustomBox.new(@node, input_vtx, output_vtx)
      @env.add_box(box)
      # ...
    end
  end
end
```

### 2. AST.create_nodeへの追加

`AST.create_node`メソッドに、新しいノード型に対応するケースを追加します：

```ruby
def self.create_node(node, env)
  case node
  # 既存のケース...
  when Prism::CustomNodeType
    CustomNode.new(node, env)
  end
end
```

## 新しいBoxの追加

TypeProfに新しいBoxを追加するには、以下の手順に従います：

### 1. Boxクラスの定義

`Box`クラスのサブクラスとして、新しいBoxクラスを定義します：

```ruby
module TypeProf::Core::Graph
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
        result_ty = process_type(ty)
        changes.add_type(@output_vtx, result_ty)
      end
    end

    private

    def process_type(ty)
      # 型の処理ロジック
      # ...
    end
  end
end
```

### 2. Boxの使用

新しいBoxを使用するコードを実装します：

```ruby
# Boxの作成
input_vtx = Source.new
output_vtx = Source.new
box = CustomBox.new(node, input_vtx, output_vtx)
env.add_box(box)

# 入力の設定
input_vtx.add_type(some_type)
```


## 新しいフィルタの追加

TypeProfに新しいフィルタを追加するには、以下の手順に従います：

### 1. フィルタクラスの定義

`Filter`クラスのサブクラスとして、新しいフィルタクラスを定義します：

```ruby
module TypeProf::Core::Graph
  class CustomFilter < Filter
    def initialize(positive)
      @positive = positive
    end

    def filter(vtx, changes)
      result = Source.new
      vtx.each_type do |ty|
        # フィルタリングロジック
        if matches?(ty) == @positive
          changes.add_type(result, ty)
        end
      end
      result
    end

    private

    def matches?(ty)
      # 型のマッチングロジック
      # ...
    end
  end
end
```

### 2. フィルタの使用

新しいフィルタを使用するコードを実装します：

```ruby
# フィルタの作成
filter = CustomFilter.new(true)

# フィルタの適用
filtered_vtx = filter.filter(original_vtx, changes)
```

## LSP機能の拡張

TypeProfのLSP機能を拡張するには、以下の手順に従います：

### 1. サーバーメソッドの追加

`Server`クラスに新しいメソッドを追加します：

```ruby
module TypeProf::LSP
  class Server
    # 既存のコード...

    def custom_request(params)
      # カスタムリクエストの処理
      # ...
      return result
    end
  end
end
```

### 2. リクエストハンドラの追加

`handle_request`メソッドに新しいリクエストタイプを追加します：

```ruby
def handle_request(id, method, params)
  case method
  # 既存のケース...
  when "typeprof/customRequest"
    result = custom_request(params)
    response(id, result)
  end
end
```

### 3. クライアント側の実装

エディタ拡張機能に、新しいリクエストを送信するコードを追加します：

```typescript
// Visual Studio Code拡張の例
const params = { /* パラメータ */ };
const result = await client.sendRequest("typeprof/customRequest", params);
```

## 実践的な例

### カスタム型の例：Optional型

```ruby
module TypeProf::Core
  class Type
    class Optional < Type
      def initialize(genv, elem_vtx)
        @elem_vtx = elem_vtx
      end

      def base_type(genv)
        genv.obj_type
      end

      def check_match(genv, changes, vtx)
        vtx.each_type do |other_ty|
          case other_ty
          when Optional
            return true if @elem_vtx.check_match(genv, changes, other_ty.elem_vtx)
          when Instance
            if other_ty.mod.cpath == [:NilClass]
              return true
            end
          end
        end
        @elem_vtx.check_match(genv, changes, vtx)
      end

      def show
        "Optional[#{ @elem_vtx.show }]"
      end

      attr_reader :elem_vtx
    end
  end
end
```

### カスタムBoxの例：MapBox

```ruby
module TypeProf::Core::Graph
  class MapBox < Box
    def initialize(node, input_vtx, output_vtx, map_func)
      super(node)
      @input_vtx = input_vtx
      @output_vtx = output_vtx
      @map_func = map_func
    end

    def run0(changes)
      @input_vtx.each_type do |ty|
        result_ty = @map_func.call(ty)
        changes.add_type(@output_vtx, result_ty)
      end
    end
  end
end
```

## まとめ

このドキュメントでは、TypeProfを拡張するための方法について説明しました。TypeProfの拡張に貢献する際は、このガイドに従ってください。
