---
sidebar_position: 12
---

# カニスター間呼び出し

ICPの開発者にとって最も重要な機能の1つは、1つのカニスターから別のカニスターの関数を呼び出すことができる機能です。このカニスター間呼び出し（**inter-canister calls**）の機能は、複数のdappで機能を再利用したり共有したりすることを可能にします。

例えば、プロフェッショナルネットワーキング、コミュニティイベントの運営、または募金活動を行うdappを作成したい場合があるでしょう。これらのdappのそれぞれは、ユーザーが友人や家族、現在または元の同僚など、いくつかの基準や共有の関心に基づいて社会的な関係を識別できるソーシャルコンポーネントを持っているかもしれません。

このソーシャルコンポーネントに対応するために、ユーザーの関係を保存するための単一のカニスターを作成し、その後、プロフェッショナルネットワーキング、コミュニティ運営、または募金アプリケーションを記述して、ソーシャル接続のためにカニスターで定義された関数をインポートして呼び出すことができます。次に、ソーシャル接続カニスターを使用する追加のアプリケーションを構築したり、ソーシャル接続カニスターが提供する機能を拡張して、より広範な開発者コミュニティに役立つものにすることができます。

この例では、上記のようなプロジェクトやユースケースの基盤として使用できるカニスター間呼び出しを設定する簡単な方法を示します。

## 例

次のコードは`Canister1`のものです：

```ts
import Canister2 "canister:canister2";

persistent actor Canister1 {

  public func main() : async Nat {
    return await Canister2.getValue();
  };

};
```

次に、`Canister2`のコードは次の通りです：

```ts
import Debug "mo:base/Debug";

persistent actor Canister2 {
  public func getValue() : async Nat {
    Debug.print("Hello from canister 2!");
    return 10;
  };
};
```

`canister1`から`canister2`へのカニスター間呼び出しを行うには、次の`dfx`コマンドを使用します：

```sh
dfx canister call canister1 main
```

出力は次のようになります：

```sh
2023-06-15 15:53:39.567801 UTC: [Canister ajuq4-ruaaa-aaaaa-qaaga-cai] Hello from canister 2!
(10 : nat)
```

また、次のコードを`canister1`に追加して、以前にデプロイしたカニスターのIDを使ってアクセスすることもできます：

```ts
persistent actor {

  public func main(canisterId: Text) : async Nat {
    let canister2 = actor(canisterId): actor { getValue: () -> async Nat };
    return await canister2.getValue();
  };

};
```

次に、以下の呼び出しを使用します。`canisterID`を以前にデプロイしたカニスターの主キーIDに置き換えます：

```sh
dfx canister call canister1 main "canisterID"
```

## 高度な使用法

メソッド名や入力型がコンパイル時に不明な場合、`ExperimentalInternetComputer`モジュールを使用して任意のカニスターのメソッドを呼び出すことができます。

次の例は、特定のユースケースに合わせて変更できるものです：

```ts
import IC "mo:base/ExperimentalInternetComputer";
import Debug "mo:base/Debug";

persistent actor AdvancedCanister1 {
  public func main(canisterId : Principal) : async Nat {
    // メソッド名と入力引数を定義
    let name = "getValue";
    let args = (123);

    // メソッドを呼び出す
    let encodedArgs = to_candid (args);
    let encodedValue = await IC.call(canisterId, name, encodedArgs);

    // 戻り値をデコード
    let ?value : ?Nat = from_candid encodedValue
        else Debug.trap("Unexpected return value");
    return value;
  }
}
```

```ts
import Debug "mo:base/Debug";

persistent actor AdvancedCanister2 {

  public func getValue(number: Nat) : async Nat {
     Debug.print("Hello from advanced canister 2!");
     return number * 2;
  };

};
```
