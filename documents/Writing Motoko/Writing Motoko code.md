---
sidebar_position: 1
---

# Motokoコードの作成

Motokoプログラミング言語は、ICP上で次世代の分散型アプリケーションを構築したい開発者のために設計された、新しい現代的で型安全な言語です。ICPのユニークな機能をサポートするように特別に設計されており、使い慣れた、かつ堅牢なプログラミング環境を提供します。新しい言語であるMotokoは、常に進化を続けており、新機能や改善が追加されています。

Motokoコンパイラ、ドキュメント、その他のツールは[オープンソース](https://github.com/dfinity/motoko)で、Apache 2.0ライセンスで公開されています。貢献を歓迎しています。

## アクター

[カニスタースマートコントラクト](https://internetcomputer.org/docs/current/developer-docs/getting-started/development-workflow)は、Motokoの[アクター](actors-async.md)として表現されます。アクターは、自分の状態を完全にカプセル化した自律的なオブジェクトであり、他のアクターと非同期メッセージを介してのみ通信します。

例えば、このコードは状態を持つ`Counter`アクターを定義しています。

```ts
actor Counter {

  var value = 0;

  public func inc() : async Nat {
    value += 1;
    return value;
  };
}
```

このアクターの単一の公開関数`inc()`は、他のアクターや自分自身によって呼び出され、プライベートフィールド`value`の現在の状態を更新および読み取ることができます。

## 非同期メッセージ

ICP上では、[カニスターは通信できます](https://internetcomputer.org/docs/current/developer-docs/smart-contracts/call/overview) 他のカニスターと非同期メッセージを送信することで。非同期メッセージは、**未来**を返す関数呼び出しであり、`await`構文を使用して未来が完了するまで実行を停止することができます。このシンプルな機能は、他の言語で必要となる明示的な非同期コールバックのループを作成するのを避けます。

``` ts
actor Factorial {

  var last = 1;

  public func next() : async Nat {
    last *= await Counter.inc();
    return last;
  }
};

ignore await Factorial.next();
ignore await Factorial.next();
await Factorial.next();
```

## モダンな型システム

Motokoは、JavaScriptやその他の人気のある言語に馴染みのある開発者が直感的に使えるように設計されていますが、構造型、ジェネリクス、バリアント型、静的チェックされたパターンマッチングなど、モダンな特徴も提供しています。

``` ts
type Tree<T> = {
  #leaf : T;
  #branch : {left : Tree<T>; right : Tree<T>};
};

func iterTree<T>(tree : Tree<T>, f : T -> ()) {
  switch (tree) {
    case (#leaf(x)) { f(x) };
    case (#branch{left; right}) {
      iterTree(left, f);
      iterTree(right, f);
    };
  }
};

// Compute the sum of all leaf nodes in a tree
let tree = #branch { left = #leaf 1; right = #leaf 2 };
var sum = 0;
iterTree<Nat>(tree, func (leaf) { sum += leaf });
sum
```

## 自動生成されるIDLファイル

Motokoアクターは、常に型付きのインターフェースをクライアントに提供します。このインターフェースは、引数と結果の型を持つ名前付き関数のスイートとして表現されます。

MotokoコンパイラとIC SDKは、このインターフェースを[Candid](candid-ui.md)という言語中立のフォーマットで出力できます。他のカニスター、ブラウザ内コード、Candidをサポートするモバイルアプリは、アクターのサービスを利用できます。MotokoコンパイラはCandidファイルを読み書きでき、Motokoは他のプログラミング言語で実装されたカニスターとシームレスに連携することができます（それらもCandidをサポートしている場合）。

例えば、前述のMotoko `Counter`アクターは、以下のCandidインターフェースを持っています：

``` candid
service Counter : {
  inc : () -> (nat);
}
```

## 直交的永続性

ICPは、カニスターが実行される際に、そのメモリや他の状態を永続化します。Motokoアクターの状態、つまりそのメモリ内のデータ構造は無期限に存続します。アクターの状態は明示的に復元したり、外部ストレージに保存したりする必要はありません。

例えば、以下の`Registry`アクターは、テキスト名に順番にIDを割り当てますが、ハッシュテーブルの状態は、アクターの状態が複数のICPノードマシンに複製され、通常はメモリ内に常駐していないにもかかわらず、呼び出し間で保持されます。

```ts
import Text "mo:base/Text";
import Map "mo:base/HashMap";

actor Registry {

  let map = Map.HashMap<Text, Nat>(10, Text.equal, Text.hash);

  public func register(name : Text) : async () {
    switch (map.get(name)) {
      case null {
        map.put(name, map.size());
      };
      case (?_) { };
    }
  };

  public func lookup(name : Text) : async ?Nat {
    map.get(name);
  };
};

await Registry.register("hello");
(await Registry.lookup("hello"), await Registry.lookup("world"))
```

## アップグレード

Motokoは、カニスターのコードを[アップグレード](../canister-maintenance/upgrades.md)する際に、カニスターのデータを保持するための多数の機能を提供します。

例えば、Motokoでは特定の変数を`stable`として宣言できます。これらの変数は、カニスターのアップグレードを跨いで自動的に保持されます。

例えば、安定したカウンターを考えてみましょう：

``` ts
actor Counter {

  stable var value = 0;

  public func inc() : async Nat {
    value += 1;
    return value;
  };
}
```

これはインストールされ、*n*回インクリメントされ、その後アップグレードされても中断されません：

```ts
actor Counter {

  stable var value = 0;

  public func inc() : async Nat {
    value += 1;
    return value;
  };

  public func reset() : async () {
    value := 0;
  }
}
```

`value`は`stable`として宣言されているため、サービスの現在の状態、*n*はアップグレード後も保持されます。カウントは`0`から再開するのではなく、*n*から続行されます。

新しいインターフェースは前のインターフェースと互換性があり、既存のクライアントがカニスターを参照し続けることができます。新しいクライアントは、追加された`reset`関数などのアップグレードされた機能を活用できます。

安定した変数の宣言をより便利にし、`stable`宣言を忘れないようにするために、Motokoではアクター全体に`persistent`キーワードを付けることができます。`persistent`アクターでは、すべての宣言はデフォルトで`stable`です。明示的に`transient`としてマークされた宣言のみがアップグレード時に破棄されます。

```ts
persistent actor Counter {

  var value = 0; // implicitly stable

  transient var invocations = 0; // reset on upgrade

  public func inc() : async Nat {
    value += 1;
    invocations += 1;
    value;
  };

  public func reset() : async () {
    value := 0;
  };

  public func getInvocations() : async Nat {
    invocations
  }

}
```

この例では、`value`は暗黙的に安定しており、`invocations`はアップグレードで保持されない一時的な宣言です：`inc`が最初にインストールまたは最後にアップグレードされてからの呼び出し回数を数えます。

安定した変数だけでは解決できないシナリオの場合、Motokoはユーザー定義のアップグレードフックを提供します。これにより、アップグレードの直前と直後に任意の状態を安定した変数に移行することができます。

## ソースコードの構成

Motokoでは、`main.mo`ファイルからコードの異なる部分を別々のモジュールに分割することができます。これにより、大きなソースコードを小さく、より管理しやすい部分に分割するのに役立ちます。

一般的なアプローチの一つは、型定義を`main.mo`ファイルから除外し、代わりに`Types.mo`ファイルに含めることです。

もう一つのアプローチは、`main.mo`ファイルで安定した変数と公開メソッドを宣言し、すべてのロジックと型を他のファイルに分割することです。このワークフローは効率的な単体テストに有益です。

## 次のステップ

Motokoコードの作成を始めるには、上記で説明したいくつかの概念に関する詳細なドキュメントを読みましょう：

- [アクター](actors-async.md)

- [アクタークラス](actor-classes.md)

- [非同期データ](async-data.md)

- [呼び出し元識別](caller-id.md)

Motokoプログラミング言語は、[IC SDK](https://internetcomputer.org/docs/current/developer-docs/setup/install)の各リリースとMotokoコンパイラの更新に伴い進化し続けています。新しい機能を試して、何が変更されたのかを確認するために、定期的にチェックしてください。
