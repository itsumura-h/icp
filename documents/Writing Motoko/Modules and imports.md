以下が日本語に翻訳した内容です：

---

# モジュールとインポート

Motokoの設計は、組み込み型や操作を最小化することを目指しています。組み込み型の代わりに、Motokoは多くの一般的な操作を処理するためのベースライブラリを提供しており、これにより言語が完結したもののように感じられます。このベースライブラリはまだ進化中で、コア機能をサポートするモジュールが含まれており、ベースライブラリのAPIは時間とともにさまざまな程度で変更される可能性があります。特に、ベースライブラリに含まれるモジュールと関数の数とサイズが劇的に増加する可能性があることを留意してください。ベースライブラリモジュールの更新により、プログラムを互換性を保つために更新する必要がある破壊的変更が導入される場合があります。破壊的変更は[Motokoのマイグレーションガイド](../migration-guides/overview.md)で通知されます。

このセクションでは、`module`と`import`キーワードを使用する異なるシナリオの例を示します。

## ベースライブラリからのインポート

[Motokoベースライブラリのオンラインドキュメント](../base/index.md)をご覧ください。

Motokoベースモジュールのソースコードは、オープンソースの[リポジトリ](https://github.com/dfinity/motoko-base)にあります。

リポジトリには、Motokoベースパッケージの現在のドキュメントをローカルに生成するための手順が記載されています。

ベースライブラリからインポートするには、`import`キーワードを使用し、ローカルモジュール名とインポート宣言でモジュールが見つかるURLを指定します。例えば：

```ts
import Debug "mo:base/Debug";
Debug.print("hello world");
```

この例では、`mo:`プレフィックスを使ってMotokoモジュールであることを示し、`.mo`ファイル拡張子は省略されています。その後、`base/`ベースライブラリパスとモジュール名`Debug`を使用しています。

モジュールから特定の名前付き値のサブセットをインポートするには、オブジェクトパターン構文を使用します：

```ts
import { map; find; foldLeft = fold } = "mo:base/Array";
```

この例では、`map`と`find`関数はそのままインポートされ、`foldLeft`関数は`fold`に名前が変更されています。

## ローカルファイルからのインポート

Motokoでプログラムを記述する別の一般的な方法は、ソースコードを異なるモジュールに分割することです。例えば、次のようなモデルを使用してアプリケーションを設計することが考えられます：

- 状態を変更するアクターと関数を含む`main.mo`ファイル。
- カスタムタイプ定義をすべて含む`types.mo`ファイル。
- アクター外で動作する関数を含む`utils.mo`ファイル。

このシナリオでは、3つのファイルを同じディレクトリに配置し、ローカルインポートを使用して必要な場所で関数を使用可能にします。

例えば、`main.mo`ファイルには次のような行が含まれます：

```ts no-repl
import Types "types";
import Utils "utils";
```

これらの行はローカルプロジェクトからモジュールをインポートしており、Motokoライブラリのインポートではないため、`mo:`プレフィックスは使用されません。

この例では、`types.mo`と`utils.mo`ファイルは`main.mo`ファイルと同じディレクトリにあります。再度、インポートでは`.mo`ファイル拡張子は使用されません。

## 他のパッケージやディレクトリからのインポート

他のパッケージやローカルディレクトリ以外のディレクトリからモジュールをインポートすることもできます。

例えば、以下の行は`redraw`パッケージからモジュールをインポートします：

```ts no-repl
import Render "mo:redraw/Render";
import Mono5x5 "mo:redraw/glyph/Mono5x5";
```

プロジェクトの依存関係は、パッケージマネージャーまたは`dfx.json`設定ファイルを使用して定義できます。

この例では、`Render`モジュールは`redraw`パッケージのデフォルトのソースコード位置にあり、`Mono5x5`モジュールは`redraw`パッケージのサブディレクトリ`glyph`にあります。

## パッケージマネージャーからのインポート

サードパーティのパッケージをダウンロードしてインストールするには、[Mops](https://mops.one)や[Vessel](https://github.com/dfinity/vessel)などのパッケージマネージャーを使用できます。

どちらのパッケージマネージャーも使用するには、プロジェクトの`dfx.json`ファイルを編集して、`packtool`を指定します。例えば：

```json
{
  "defaults": {
    "build": {
      "packtool": "mops sources"
    }
  }
}
```

Vesselの場合は、`vessel sources`を使用します。

次に、`mops` CLIツールを使用してパッケージをダウンロードするには、次のコマンドを使用します：

```sh
mops add vector
```

Vesselの場合は、`vessel.dhall`ファイルを編集して、プロジェクトでインポートするパッケージを含めます。

その後、次のようにインポートします：

```ts no-repl
import Vec "mo:vector";
import Vec "mo:vector/Class";
```

## アクタークラスのインポート

モジュールのインポートは通常、ローカル関数や値のライブラリをインポートするために使用されますが、アクタークラスのインポートにも使用できます。インポートされたファイルが名前付きアクタークラスである場合、インポートされたフィールドのクライアントはそのアクタークラスを含むモジュールを見ます。

このモジュールには、アクタークラスのインターフェースを記述した型定義と、アクタークラスの新しいインスタンスを非同期で返す関数の2つのコンポーネントがあります。

例えば、Motokoアクターは以下のように`Counter`クラスをインポートしてインスタンス化できます：

`Counters.mo`:

```ts name=Counters file=../examples/Counters.mo
persistent actor class Counter(init : Nat) {
  var count = init;

  public func inc() : async () { count += 1 };

  public func read() : async Nat { count };

  public func bump() : async Nat {
    count += 1;
    count;
  };
};
```

`CountToTen.mo`:

```ts no-repl file=../examples/CountToTen.mo
import Counters "Counters";
import Debug "mo:base/Debug";
import Nat "mo:base/Nat";

persistent actor CountToTen {
  public func countToTen() : async () {
    let C : Counters.Counter = await Counters.Counter(1);
    while ((await C.read()) < 10) {
      Debug.print(Nat.toText(await C.read()));
      await C.inc();
    };
  }
};
await CountToTen.countToTen()
```

`Counters.Counter(1)`の呼び出しは、ネットワーク上に新しいカウンターをインストールします。インストールは非同期で行われるため、呼び出し元はその結果を`await`する必要があります。

`Counters.Counter`の型注釈`: Counters.Counter`は冗長ですが、アクタークラスの型が必要なときに使用可能であることを示すために含まれています。

## 他のカニスターからのインポート

他のカニスターからアクターとその共有関数をインポートすることもできます。その場合、`mo:`プレフィックスの代わりに`canister:`プレフィックスを使用します。

:::note

Motokoライブラリとは異なり、インポートされたカニスターはRustや別のMotokoバージョンなど、他の言語で実装されていても構いません。その場合、カニスターのCandidインターフェースがエクスポートされます。

:::

例えば、以下のようなプロジェクトがあるとしましょう：

- BigMap（Rustで実装）
- Connectd（Motokoで実装）
- LinkedUp（Motokoで実装）

これらの3つのカニスターは、プロジェクトの`dfx.json`設定ファイルに宣言され、`dfx build`を実行することでコンパイルされます。

次のようにして、Motokoアクターの`LinkedUp`アクターから`BigMap`と`Connectd`カニスターをインポートできます：

```ts no-repl
import BigMap "canister:BigMap";
import Connectd "canister:connectd";
```

カニスターをインポートする際は、インポートされたカニスターの型が**Motokoアクター**であり、**Motokoモジュール**ではないことに注意してください。この違いは、いくつかのデータ構造がどのように型付けされるかに影響を与える可能性があります。

インポートされたカニスターアクターの場合、型はカニスターのCandid `project-name.did`ファイルから派生し、Motoko自体からではありません。

Motokoアクター型からCandidサービス型への変換は通常1対1ですが、いくつか

の異なるMotoko型が同じCandid型にマッピングされることがあります。例えば、Motokoの[`Nat32`](../base/Nat32.md)型と`Char`型はどちらもCandid型[`Nat32`](../base/Nat32.md)としてエクスポートされますが、`Nat32`はMotokoで[`Nat32`](../base/Nat32.md)としてインポートされます。

インポートされたカニスター関数の型は、元のMotokoコードで実装されている型とは異なる場合があります。例えば、Motoko関数が`shared Nat32 -> async Char`という型を持っていた場合、そのエクスポートされたCandid型は`(nat32) -> (nat32)`となりますが、このCandid型からインポートされるMotoko型は、実際には正しい型である`shared Nat32 -> async Nat32`となります。

## インポートされたモジュールの名前付け

最も一般的な慣習は、インポートされたモジュールをモジュール名で識別することですが、これは必須ではありません。例えば、名前の衝突を避けたり、名前付け規則を簡素化するために異なる名前を使用したい場合があります。

以下の例では、`List`ベースライブラリモジュールをインポートする際に、架空の`collections`パッケージからの別の`List`ライブラリとの衝突を避けるために異なる名前を使用しています：

```ts no-repl
import List "mo:base/List:";
import Sequence "mo:collections/List";
import L "mo:base/List";
```
