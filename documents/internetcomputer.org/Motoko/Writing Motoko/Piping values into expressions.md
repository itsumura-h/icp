---
sidebar_position: 20
---

# 式への値のパイピング

いくつかの関数適用を含む深くネストされた式は、時には読みづらくなることがあります。

```ts file=../examples/Unpiped.mo#L1-L8
import Iter "mo:base/Iter";
import List "mo:base/List";

{ multiples =
   List.filter<Nat>(
     Iter.toList(Iter.range(0, 10)),
     func n { n % 3 == 0 }) };
```

この式は、数字の範囲 `0`..`10` を取り、それをリストに変換し、そのリストから3の倍数をフィルタリングし、結果を含むレコードを返します。

そのような式をより読みやすくするために、Motoko ではパイプ演算子 `<exp1> |> <exp2>` を使用できます。この演算子は最初の引数 `<exp1>` を評価し、その値を `<exp2>` 内で特別なプレースホルダー式 `_` を使用して参照できるようにします。

これを使用することで、前述の式を次のように書き換えることができます：

```ts file=../examples/Piped.mo#L1-L8
import Iter "mo:base/Iter";
import List "mo:base/List";

Iter.range(0, 10) |>
  Iter.toList _ |>
    List.filter<Nat>(_, func n { n % 3 == 0 }) |>
      { multiples = _ };
```

これで、操作の順序が上記の説明に対応するようになります。パイプ式 `<exp1> |> <exp2>` は、次のように `<exp1>` を予約されたプレースホルダー識別子 `p` にバインディングしてから `<exp2>` を返す構文糖に過ぎません：

``` bnf
do { let p = <exp1>; <exp2> }
```

通常アクセスできないプレースホルダー識別子 `p` は、プレースホルダー式 `_` によってのみ参照できます。同じパイプ操作内で `_` を複数回参照することができ、それは同じ値を参照します。

`_` をパイプ操作の外で式として使用することはできません。未定義のため、エラーになります。

例えば、以下の例ではコンパイル時エラー「型エラー [M0057]、未バインド変数 _」が発生します：

```ts no-repl
let x = _;
```

内部的にコンパイラは、予約された識別子 `_` を上記のプレースホルダー `p` の名前として使用するため、この `let` は未定義の変数を参照しているだけです。

パイプに関する詳細は、[言語マニュアルのパイプについてのページ](../reference/language-manual#pipe-operators-and-placeholder-expressions)を参照してください。
