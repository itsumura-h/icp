---
sidebar_position: 1
---

# サイクル

ICP 上でカニスターのリソースの使用は [サイクル](/docs/current/developer-docs/defi/cycles/converting_icp_tokens_into_cycles) によって測定され、支払われます。

ICP 上にデプロイされた Motoko プログラムでは、各アクターはカニスターを表し、関連するサイクル残高を持っています。サイクルの所有権はアクター間で転送することができます。サイクルは共有関数呼び出しを通じて選択的に送受信されます。呼び出し元は呼び出しでサイクルを転送することを選択でき、呼び出し先は呼び出し元が利用可能にしたサイクルを受け入れることを選択できます。明示的に指示しない限り、呼び出し元によってサイクルは転送されず、呼び出し先によってサイクルは受け入れられません。

呼び出し先は、アクターの現在の残高で決まる制限まで、利用可能なサイクルのすべて、一部、または none を受け入れることができます。残りのサイクルは呼び出し元に返金されます。もし呼び出しがトラップする場合、その伴うサイクルはすべて自動的に呼び出し元に返金され、損失はありません。

将来的には、Motoko がサイクルをより安全に扱うための専用の構文や型を採用するかもしれません。現在、サイクルの管理は、`base` パッケージの [ExperimentalCycles](../base/ExperimentalCycles.md) ライブラリを通じた低レベルの命令型 API を使って提供されています。

:::note

このライブラリは変更される可能性があり、Motoko の後のバージョンでサイクルに対するより高レベルのサポートに置き換えられる可能性があります。

:::

## [`ExperimentalCycles`](../base/ExperimentalCycles.md) ライブラリ

[`ExperimentalCycles`](../base/ExperimentalCycles.md) ライブラリは、アクターの現在のサイクル残高の監視、サイクルの転送、および返金の監視のための命令型操作を提供します。

このライブラリは以下の操作を提供します：

- `func balance() : (amount : Nat)`：アクターの現在のサイクル残高を `amount` として返します。`balance()` 関数は状態を持ち、`accept(n)` の呼び出しや、サイクルを `add` した後の関数呼び出し、または `await` からの再開後に異なる値を返すことがあります。

- `func available() : (amount : Nat)`：現在利用可能なサイクルの `amount` を返します。これは現在の呼び出し元から受け取ったサイクルの量で、これまでこの呼び出しで `accept` された累積量を引いたものです。現在の共有関数または `async` 式から `return` または `throw` で抜けると、残りの利用可能なサイクル量は自動的に呼び出し元に返金されます。

- `func accept<system>(amount : Nat) : (accepted : Nat)`：`available()` から `balance()` に `amount` を転送します。実際に転送された量を返します。例えば、利用可能なサイクルが少ない場合やカニスターの残高制限に達した場合は、要求された量より少ない場合があります。`system` 能力が必要です。

- `func add<system>(amount : Nat) : ()`：次のリモート呼び出し（つまり、共有関数呼び出しや `async` 式）のために転送される追加のサイクル量を示します。呼び出し時に、前回の呼び出し以降に `add` された合計が `balance()` から差し引かれます。この合計が `balance()` を超えると、呼び出し元はトラップし、呼び出しが中止されます。`system` 能力が必要です。

- `func refunded() : (amount : Nat)`：現在のコンテキストの最後の `await` で返金されたサイクル量を報告します。まだ `await` が発生していない場合はゼロを返します。`refunded()` の呼び出しは情報提供のみで、`balance()` には影響を与えません。返金は自動的に現在の残高に追加され、`refunded` を使ってそれを観察しなくても、返金は確実に行われます。

:::danger

サイクルは消費された計算リソースを測定するため、`balance()` の値は通常、1回の共有関数呼び出しから次回の共有関数呼び出しにかけて減少します。

`add` で追加された量を記録する暗黙的なレジスタは、共有関数に入るとリセットされ、各共有関数呼び出し後や `await` から再開する際にもリセットされます。

:::

### 例

ここでは、[`ExperimentalCycles`](../base/ExperimentalCycles.md) ライブラリを使用して、サイクルを貯金するシンプルな貯金箱プログラムを実装します。

私たちの貯金箱には、暗黙の所有者、`benefit` コールバック、固定の `capacity` があり、すべてが構築時に提供されます。コールバックは引き出された額を転送するために使用されます。

```ts name=PiggyBank file=../examples/PiggyBank.mo
import Cycles "mo:base/ExperimentalCycles";

shared(msg) persistent actor class PiggyBank(
  benefit : shared () -> async (),
  capacity: Nat
  ) {

  transient let owner = msg.caller;

  var savings = 0;

  public shared(msg) func getSavings() : async Nat {
    assert (msg.caller == owner);
    return savings;
  };

  public func deposit() : async () {
    let amount = Cycles.available();
    let limit : Nat = capacity - savings;
    let acceptable =
      if (amount <= limit) amount
      else limit;
    let accepted = Cycles.accept<system>(acceptable);
    assert (accepted == acceptable);
    savings += acceptable;
  };

  public shared(msg) func withdraw(amount : Nat)
    : async () {
    assert (msg.caller == owner);
    assert (amount <= savings);
    Cycles.add<system>(amount);
    await benefit();
    let refund = Cycles.refunded();
    savings -= amount - refund;
  };

}
```

貯金箱の所有者は、コンストラクタ `PiggyBank()` の暗黙の呼び出し元である `shared(msg)` を使って識別されます。フィールド `msg.caller` は [`Principal`](../base/Principal.md) であり、将来の参照のためにプライベート変数 `owner` に格納されます。この構文の詳細については [プリンシパルと呼び出し元識別](../writing-motoko/caller-id.md) を参照してください。

貯金箱は最初は空で、現在の `savings` はゼロです。

`owner` からの呼び出しのみが次の操作を行えます：

- 現在の貯金額（`getSavings()` 関数）を照会する、または
- 貯金から額を引き出す（`withdraw(amount)` 関数）。

呼び出し元の制限は、`assert (msg.caller == owner)` の文で強制され、失敗すると関数がトラップし、残高が表示されることなくサイクルが移動することもありません。

どの呼び出し元でも `deposit` 関数を使ってサイクルを預けることができますが、貯金が `capacity` を超えない限りです。預金関数は利用可能な額の一部しか受け付けないため、制限を超える預金を行った呼び出し元には、未受け入れのサイクルが暗黙的に返金されます。返金は自動的に行われ、ICP インフラによって保証されます。

サイクルの転送は呼び出し元から呼び出し先への一方向で行われるため、サイクルを取得するには、コンストラクタから引き渡された `benefit` 関数を使って明示的なコールバックが必要です。ここで、`benefit` は `withdraw` 関数で呼び出されますが、所有者として認証した後のみです。`withdraw` で `benefit` を呼び出すことにより、呼び出し元/呼び出し先の関係が逆転し、サイクルが上流に流れます。

`PiggyBank` の所有者は、`owner` とは異なる受益者を指定するコールバックを提供できます。

`PiggyBank` のインスタンスを使用する `Alice` の例を以下に示します：

```ts include=PiggyBank file=../examples/Alice.mo
import Cycles = "mo:base/ExperimentalCycles";
import Lib = "PiggyBank";

actor Alice {

  public func test() : async () {

    Cycles.add<system>(10_000_000_000_000);
    let porky = await Lib.PiggyBank(Alice.credit, 1_000_000_000);

    assert (0 == (await porky.getSavings()));

    Cycles.add<system>(1_000_000);
    await porky.deposit();
    assert (1_000_000 == (await porky.getSavings()));

    await porky.withdraw(500_000);
    assert (500_000 == (await porky.getSavings()));

    await porky.withdraw(500_000);
    assert (0 == (await porky.getSavings()));

    Cycles.add<system>(2_000_000_000);
    await porky.deposit();
    let refund = Cycles.refunded();
    assert (1_000_000_000 == refund);
    assert (1_000_000_000 == (await porky.getSavings()));

  };

  // Callback for accepting cycles from PiggyBank
  public func credit() : async () {
    let available = Cycles.available();
    let accepted = Cycles.accept<system>(available);
    assert (accepted == available);
  }

}
```

`Alice` は `PiggyBank` アクタークラスをライブラリとしてインポートし、新しい `PiggyBank` アクターを必要に応じて作成します。

アクションの大部分は `Alice` の `test()` 関数で行われます：

- `Alice` は `PiggyBank` を実行するために自分のサイクル `10_000_000_000_000` を専用にし、`PiggyBank` の新しいインスタンス `porky` を作成する直前に `Cycles.add(10_000_000_000_000)` を呼び出し、コールバック `Alice.credit` と容量 (`1_000_000_000`) を渡します。`Alice.credit` を渡すことで、`Alice` は引き出しの受益者として指定されます。`10_000_000_000_000` サイクルは、プログラムの初期化コードによる追加のアクションなしで `porky` の残高にクレジットされます。このように、電気式貯金箱が使用されるときに自分自身のリソースを消費するように考えることができます。`PiggyBank` の構築は非同期であるため、`Alice` は結果を `await` する必要があります。

- `porky` を作成した後、最初に `porky.getSavings()` がゼロであることを `assert` を使って検証します。

- `Alice` はサイクルのうち `1_000_000` を `Cycles.add<system>(1_000_000)` で `porky.deposit()` への次の呼び出しに転送します。このサイクルは、`porky.deposit()` の呼び出しが成功した場合にのみ `Alice` の残高から消費されます。

- `Alice` はその後、半分の `500_000` を引き出し、`porky` の貯金が半減したことを確認します。最終的に `Alice` はサイクルを `Alice.credit()` へのコールバックで受け取ります。受け取ったサイクルは、`porky.withdraw()` で `add` されたサイクルと正確に一致します。

- `Alice` はさらに `500_000` サイクルを引き出して貯金をゼロにします。

- `Alice` は `porky` に `2_000_000_000` サイクルを預けようとしますが、これは `porky` の容量を半分超えているため、`porky` は `1_000_000_000` を受け入れ、残りの `1_000_000_000` は `Alice` に返金されます。`Alice` は返金額（`Cycles.refunded()`）を検証し、それが自動的に彼女の残高に戻ったことを確認します。また、`porky` の調整された貯金額も検証します。

- `Alice` の `credit()` 関数は、`Cycles.accept<system>(available)` を呼び出すことで利用可能なすべてのサイクルを受け入れ、実際に受け入れた量を `assert` で確認します。

:::note

この例では、`Alice` はすでに所有している利用可能なサイクルを使用しています。

:::

:::danger

`porky` がサイクルを消費するため、`porky` は `Alice` がサイクルを引き出す前に、`Alice` のサイクル貯金の一部またはすべてを消費する可能性があります。

:::

<img src="https://github.com/user-attachments/assets/844ca364-4d71-42b3-aaec-4a6c3509ee2e" alt="Logo" width="150" height="150" />
