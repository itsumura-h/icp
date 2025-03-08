---
sidebar_position: 23
---

# データと振る舞いの共有

Motoko では、可変状態は常にアクターにプライベートです。しかし、2つのアクターはメッセージデータを共有でき、そのメッセージはアクターを指すことができ、アクター自身や互いのアクターを参照することができます。さらに、メッセージは個々の関数を参照することもでき、これらの関数が `shared` として定義されていれば可能です。

これらのメカニズムを通じて、2つのアクターは非同期メッセージ送信を通じてその振る舞いを調整できます。

## アクターを使ったパブリッシャー・サブスクライバー パターン

このセクションの例では、アクターがどのように関数を共有するかを示し、[パブリッシャー・サブスクライバー パターン](https://en.wikipedia.org/wiki/Publish-subscribe_pattern)の変種に焦点を当てています。パブリッシャー・サブスクライバーパターンでは、**パブリッシング**アクターが **サブスクライバー**アクターのリストを記録し、パブリッシャーの状態で重要な変化が発生したときにサブスクライバーに通知します。例えば、パブリッシャーアクターが新しい記事を公開した場合、サブスクライバーアクターは新しい記事が利用可能であることを通知されます。

以下の例では、Motokoで2つのアクターを使ってパブリッシャー・サブスクライバー関係のバリエーションを構築しています。

このパターンを使用する動作するプロジェクトの完全なコードを見たい場合は、[pubsub](https://github.com/dfinity/examples/tree/master/motoko/pubsub)の例を[examplesリポジトリ](https://github.com/dfinity/examples)で確認してください。

### サブスクライバーアクター

以下の `Subscriber` アクタータイプは、サブスクライバーアクターが公開し、パブリッシャーアクターが呼び出す可能性のあるインターフェースを提供します：

```ts name=tsub
type Subscriber = actor {
  notify : () -> ()
};
```

- `Publisher` はこのタイプを使用して、サブスクライバーをデータとして格納するデータ構造を定義します。

- 各 `Subscriber` アクターは、上記の `Subscriber` アクタータイプの署名で説明されているように、`notify` 更新関数を公開します。

サブタイピングによって、`Subscriber` アクターはこのタイプ定義に記載されていない追加のメソッドを含むことができます。

簡単のため、`notify` 関数は関連する通知データを受け取り、サブスクライバーについての新しいステータスメッセージをパブリッシャーに返すと仮定します。例えば、サブスクライバーは通知データに基づいてサブスクリプション設定を変更する場合があります。

### パブリッシャーアクター

パブリッシャー側のコードは、サブスクライバーの配列を保持します。簡単のため、各サブスクライバーは `subscribe` 関数を使って一度だけサブスクライブすると仮定します：

```ts no-repl
import Array "mo:base/Array";

persistent actor Publisher {

  var subs : [Subscriber] = [];

  public func subscribe(sub : Subscriber) {
    subs := Array.append<Subscriber>(subs, [sub]);
  };

  public func publish() {
    for (sub in subs.vals()) {
      sub.notify();
    };
  };
}
```

後で、いくつかの未指定の外部エージェントが `publish` 関数を呼び出すと、すべてのサブスクライバーは上記で定義された `notify` メッセージを受け取ります。

### サブスクライバーメソッド

最も単純な場合、サブスクライバーアクターには以下のメソッドがあります：

- `init` メソッドを使って、パブリッシャーからの通知をサブスクライブします。

- `Subscriber` アクタータイプで指定された `notify` 関数に従って通知を受け取ります。

- 受け取った通知の数を `count` 変数に格納するような、蓄積された状態に対するクエリを許可します。

これらのメソッドを実装するコードは以下の通りです：

```ts no-repl
persistent actor Subscriber {

  var count : Nat = 0;

  public func init() {
    Publisher.subscribe(Subscriber);
  };

  public func notify() {
    count += 1;
  };

  public func get() : async Nat {
    count
  };
}
```

このアクターは `init` 関数が一度だけ呼ばれることを前提としており、強制はしていません。`init` 関数内で、`Subscriber` アクターは自身の参照を `actor { notify : () -> () };` 型で渡します。

もし `init` が複数回呼ばれた場合、アクターは複数回サブスクライブし、パブリッシャーから複数の重複した通知を受け取ることになります。この脆弱性は、上記で示した基本的なパブリッシャー・サブスクライバーデザインの結果です。より高度なパブリッシャーアクターは、重複したサブスクライバーアクターをチェックして無視することができます。

## アクター間での関数の共有

Motoko では、`shared` アクター関数をメッセージで他のアクターに送信し、その後そのアクターまたは他のアクターによって呼び出すことができます。

上記のコードは説明のために簡略化されています。完全なバージョンでは、パブリッシャー・サブスクライバーパターンに追加機能が提供され、共有関数を使用してこの関係をより柔軟にしています。

例えば、通知関数は常に `notify` として指定されます。より柔軟なデザインでは、`notify` の型のみを固定し、サブスクライバーがその `shared` 関数のいずれかを選択できるようにします。

詳細については、[完全な例](https://github.com/dfinity/examples/tree/master/motoko/pub-sub)を参照してください。

特に、サブスクライバーがインターフェースの命名スキームに縛られたくない場合を考えます。本当に重要なのは、パブリッシャーがサブスクライバーが選択した任意の関数を呼び出すことができることです。

### `shared` キーワード

この柔軟性を許可するために、アクターは他のアクターからリモート呼び出しを許可する単一の関数を共有する必要があります。単に自分自身の参照を共有するのではなく、関数そのものを共有する必要があります。

関数を共有する能力は、その関数が事前に `shared` として指定されている必要があり、型システムはこれらの関数が受け入れるデータの型と返す結果について特定のルールに従うことを強制します。特に、共有関数を通じて送信されるデータは、不変のプレーンデータ、アクター参照、または共有関数の参照で構成される共有型である必要があります。ローカル関数、メソッドを持つ適切なオブジェクト、可変配列は除外されます。

Motoko では、`shared` キーワードを省略することができます。なぜなら、アクターのパブリックメソッドは暗黙的に `shared` でなければならず、明示的に指定されていなくてもそうなっているからです。

`shared` 関数型を使用して、上記の例をより柔軟に拡張できます。例えば：

```ts
type SubscribeMessage = { callback : shared () -> (); };
```

この型は、`callback` という1つのフィールドを持つメッセージレコード型を記述しています。元の型は、`notify` という1つのメソッドを持つアクタータイプを記述しています。

```ts
type Subscriber = actor { notify : () -> () };
```

特に、`actor` キーワードは、後者の型が単なるフィールドを持つレコードではなく、少なくとも1つのメソッド `notify` を持つアクターであることを意味します。

`SubscribeMessage` 型を使うことで、`Subscriber` アクターは `notify` メソッドに代わる別の名前を選ぶことができます：

```ts no-repl
persistent actor Subscriber {

  var count : Nat = 0;

  public func init() {
    Publisher.subscribe({callback = incr;});
  };

  public func incr() {
    count += 1;
  };

  public query func get(): async Nat {
    count
  };
}
```

元のバージョンと比較して、変更されたのは `notify` を `incr` に名前を変更し、`subscribe` メッセージペイロードを `{callback = incr}` という式で作成する部分だけです。

同様に、パブリッシャーを更新して一致するインターフェースを持たせることができます：

```ts no-repl
import Array "mo:base/Array";

persistent actor Publisher {

  var subs : [SubscribeMessage] = [];

  public func subscribe(sub : SubscribeMessage) {
    subs := Array.append<SubscribeMessage>(subs, [sub]);
  };

  public func publish() {
    for (sub in subs.vals()) {
      sub.callback();
    };
  };
}
```

<img src="https://github.com/user-attachments/assets/844ca364-4d71-42b3-aaec-4a6c3509ee2e" alt="Logo" width="150" height="150" />
