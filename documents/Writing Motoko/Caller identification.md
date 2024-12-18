---
sidebar_position: 6
---

# 呼び出し元識別

Motokoの共有関数は、関数の呼び出し元に関連付けられたICP **プリンシパル**を検査できる簡単な呼び出し元識別の形式をサポートしています。プリンシパルは、ユニークなユーザーまたはカニスターを識別する値です。

関数の呼び出し元に関連するプリンシパルを使用して、プログラム内で基本的なアクセス制御を実装することができます。

## 呼び出し元識別の使用

Motokoでは、`shared`キーワードを使って共有関数を宣言します。共有関数は、`{caller : Principal}`型のオプション引数を宣言することもできます。

共有関数の呼び出し元にアクセスする方法を示すために、次のコードを考えます：

```ts
shared(msg) func inc() : async () {
  // ... msg.caller ...
}
```

この例では、共有関数`inc()`は`msg`パラメータを指定しています。これはレコードで、`msg.caller`は`msg`のプリンシパルフィールドにアクセスします。

`inc()`関数への呼び出しは変更されません。各呼び出しの際、呼び出し元のプリンシパルはユーザーではなくシステムによって提供されます。プリンシパルは悪意のあるユーザーによって偽造やスプーフィングされることはありません。

アクタークラスコンストラクタの呼び出し元にアクセスするには、アクタークラス宣言でも同じ構文を使用します。例えば：

```ts
shared(msg) persistent actor class Counter(init : Nat) {
  // ... msg.caller ...
}
```

## アクセス制御の追加

この例を拡張し、`Counter`アクターがインストーラー以外には変更できないように制限したいと仮定します。これを実現するために、アクターをインストールしたプリンシパルを`owner`変数に記録します。その後、各メソッドの呼び出し元が`owner`と一致することを確認します。以下のように実装します：

```ts
shared(msg) persistent actor class Counter(init : Nat) {

  transient let owner = msg.caller;

  var count = init;

  public shared(msg) func inc() : async () {
    assert (owner == msg.caller);
    count += 1;
  };

  public func read() : async Nat {
    count
  };

  public shared(msg) func bump() : async Nat {
    assert (owner == msg.caller);
    count := 1;
    count;
  };
}
```

この例では、`assert (owner == msg.caller)`式により、`inc()`および`bump()`関数は呼び出しが許可されていない場合にトラップし、`count`変数の変更を防ぎます。一方、`read()`関数はどの呼び出し元でも許可します。

`shared`への引数は単なるパターンです。上記をパターンマッチングを使用して書き換えることができます：

```ts
shared({caller = owner}) persistent actor class Counter(init : Nat) {

  var count : Nat = init;

  public shared({caller}) func inc() : async () {
    assert (owner == caller);
    count += 1;
  };

  // ...
}
```

:::note

シンプルなアクター宣言ではインストーラーにアクセスできません。アクターのインストーラーにアクセスする必要がある場合は、アクター宣言を引数なしのアクタークラスとして書き換えてください。

:::

## プリンシパルの記録

プリンシパルは等価性、順序付け、ハッシュ化をサポートしているため、プリンシパルを効率的にコンテナに格納し、許可リストや拒否リストを維持するなどの操作を行うことができます。プリンシパルに対する詳細な操作については、[Principal](../base/Principal.md)ベースライブラリをご覧ください。

Motokoにおける`Principal`のデータ型は共有可能かつ安定しており、`Principal`を直接比較することができます。

以下は、プリンシパルをセットに記録する方法の例です：

```ts
import Principal "mo:base/Principal";
import OrderedSet "mo:base/OrderedSet";
import Error "mo:base/Error";

persistent actor {

    transient let principalSet = OrderedSet.Make<Principal>(Principal.compare);

    // Create set to record principals
    var principals : OrderedSet.Set<Principal> = principalSet.empty();

    // Check if principal is recorded
    public shared query(msg) func isRecorded() : async Bool {
        let caller = msg.caller;
        principalSet.contains(principals, caller);
    };

    // Record a new principal
    public shared(msg) func recordPrincipal() : async () {
        let caller = msg.caller;
        if (Principal.isAnonymous(caller)) {
            throw Error.reject("Anonymous principal not allowed");
        };

        principals := principalSet.put(principals, caller)
    };
};
```

```ts
import Principal "mo:base/Principal";
import OrderedSet "mo:base/OrderedSet";
import Error "mo:base/Error";

persistent actor {

    // プリンシパルを格納するセットを作成
    transient var principalSet = Set.Make(Principal.compare);

    var principals : OrderedSet.Set<Principal> = principalSet.empty();

    // プリンシパルが記録されているか確認
    public shared query(msg) func isRecorded() : async Bool {
        let caller = msg.caller;
        principalSet.contains(principals, caller);
    };

    // 新しいプリンシパルを記録
    public shared(msg) func recordPrincipal() : async () {
        let caller = msg.caller;
        if (Principal.isAnonymous(caller)) {
            throw Error.reject("匿名プリンシパルは許可されていません");
        };

        principals := principalSet.put(principals, caller)
    };
};
```
