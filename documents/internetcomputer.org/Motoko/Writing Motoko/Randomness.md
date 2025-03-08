---
sidebar_position: 22
---

# ランダムネス

Motoko の [`Random`](../base/Random.md) ベースライブラリは、ICP 上のスマートコントラクトでランダムな値を生成するために使用できます。ICP におけるランダムネスは、ICP が暗号的なランダム値を得るために決定論的計算を使用するため、複雑なプロセスです。

低レベルでは、ICP は管理カニスターによって公開された検証可能なランダム関数（Verifiable Random Function、VRF）を使用し、Motoko の `Random` モジュールがこれを利用します。各実行ラウンドで、このランダム関数は現在のラウンドの番号を入力として使用し、新しいランダムなバイト列を生成します。

ランダムネスを使用するためには、以下のガイドラインに従う必要があります：

- ランダムネスのソースは、256ビットのチャンク（32バイトの `Blob`）で非同期的に取得できるものでなければなりません。

- ベットはランダムネスのソースが要求される前に締め切られている必要があります。これは、同じランダムネスのソースを新しいラウンドのベットに使用することは、暗号的な保証を失うことを意味します。

`Random` モジュールには `Finite` クラスと `*From` メソッドがあります。これらは前のラウンドから状態が引き継がれるリスクがありますが、パフォーマンスと便利さのために提供されています。慎重に使用する必要があります。

## `Random` モジュールの例

ランダムネスを示すために、次の例を考えます。この例では、カードのデッキをシャッフルし、そのシャッフルされた順番でカードを返します。コードには追加の情報が注釈として記載されています：

```ts file=../examples/CardShuffle.mo
// Import the necessary modules, including the Random module:
import Random = "mo:base/Random";
import Char = "mo:base/Char";
import Error = "mo:base/Error";

// Define an actor

persistent actor {

  // Define a stable variable that contains each card as a unicode character:
  var deck : ?[var Char] = ?[var
    '🂡','🂢','🂣','🂤','🂥','🂦','🂧','🂨','🂩','🂪','🂫','🂬','🂭','🂮',
    '🂱','🂲','🂳','🂴','🂵','🂶','🂷','🂸','🂹','🂺','🂻','🂼','🂽','🂾',
    '🃁','🃂','🃃','🃄','🃅','🃆','🃇','🃈','🃉','🃊','🃋','🃌','🃍','🃎',
    '🃑','🃒','🃓','🃔','🃕','🃖','🃗','🃘','🃙','🃚','🃛','🃜','🃝','🃞',
    '🃏'
  ];

  func bit(b : Bool) : Nat {
    if (b) 1 else 0;
  };

  // Use a finite source of randomness defined as `f`.
  // Return an optional random number between [0..`max`) using rejection sampling.
  // A return value of `null` indicates that `f` is exhausted and should be replaced.
  func chooseMax(f : Random.Finite, max : Nat) : ? Nat {
    assert max > 0;
    do ? {
      var n = max - 1 : Nat;
      var k = 0;
      while (n != 0) {
        k *= 2;
        k += bit(f.coin()!);
        n /= 2;
      };
      if (k < max) k else chooseMax(f, max)!;
    };
  };

  // Define a function to shuffle the cards using `Random.Finite`.
  public func shuffle() : async () {
    let ?cards = deck else throw Error.reject("shuffle in progress");
    deck := null;
    var f = Random.Finite(await Random.blob());
    var i : Nat = cards.size() - 1;
    while (i > 0) {
      switch (chooseMax(f, i + 1)) {
        case (?j) {
          let temp = cards[i];
          cards[i] := cards[j];
          cards[j] := temp;
          i -= 1;
        };
        case null { // need more entropy
          f := Random.Finite(await Random.blob());
        }
      }
    };
    deck := ?cards;
  };

  // Define a function to display the randomly shuffled cards.
  public query func show() : async Text {
    let ?cards = deck else throw Error.reject("shuffle in progress");
    var t = "";
    for (card in cards.vals()) {
       t #= Char.toText(card);
    };
    t;
  }

};
```

この例は、[Motoko Playground](https://play.motoko.org/?tag=2675232834) で見ることができます。または [GitHub](https://github.com/crusso/card-shuffle/blob/main/src/cards_backend/main.mo) でも確認できます。

:::tip

上記のソリューションでは、管理カニスターから返される256ビットのランダムビットの有限ブロブを直接使用しています。`Random.Finite` クラスは、この有限のビット供給を使用して、最大256回のコイン投げを生成し、投げることができなくなった場合は `null` を返します。

現在のビット供給が尽きた場合、コードは非同期的にさらに256ビットのブロブを要求してシャッフルを続けます。より効率的で同様に堅牢なアプローチは、最初の256ビットのブロブをシードとして順次擬似乱数生成器に使用し、無限の遅延ストリームのビットを生成して、1回の通信でシャッフルを完了する方法です。

:::

## 管理カニスターの `raw_rand` メソッドの呼び出し

また、管理カニスターの `raw_rand` エンドポイントを呼び出してランダムネスを使用することもできます：

```ts file=../examples/RawRand.mo
persistent actor {
  transient let SubnetManager : actor {
    raw_rand() : async Blob;
  } = actor "aaaaa-aa";

  public func random_bytes() : async Blob {
    let bytes = await SubnetManager.raw_rand();
    bytes;
  };
};
```

## リソース

- [オンチェーンランダムネス](https://internetcomputer.org/docs/current/developer-docs/smart-contracts/advanced-features/randomness)

- [ランダムベースライブラリのドキュメント](../base/Random.md)

<img src="https://github.com/user-attachments/assets/844ca364-4d71-42b3-aaec-4a6c3509ee2e" alt="Logo" width="150" height="150" />
