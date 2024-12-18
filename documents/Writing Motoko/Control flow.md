---
sidebar_position: 8
---

# 制御フロー

制御フローには2つの主要なカテゴリがあります：

- **宣言型** : ある値の構造が、制御と次に評価する式の選択を導くもので、`if`や`switch`式などが該当します。

- **命令型** : プログラマの命令に従って制御が急激に変更され、通常の制御フローが放棄されるものです。例えば、`break`や`continue`、また`return`や`throw`などが該当します。

命令型の制御フローは、状態変更や他の副作用（エラーハンドリングや入出力など）と一緒に使われることが多いです。

## 関数からの早期`return`

通常、関数の結果はその本体の値です。場合によっては、関数の本体の評価中に結果が評価の終わり前に得られることがあります。このような場合、`return <exp>`構文を使って計算の残りを放棄し、即座に関数から結果を返すことができます。同様に、許可されている場所では、`throw`を使ってエラーで計算を放棄することもできます。

関数が`unit`型の結果を返す場合、`return`を簡略化して`return ()`の代わりに使用することができます。

## ループとラベル

Motokoは、以下のような繰り返し構文をいくつか提供しています：

- 構造化データのメンバーを反復処理するための`for`式。
- 条件付きで終了条件を持つプログラム的な繰り返しのための`loop`式。
- エントリー条件を持つプログラム的な繰り返しのための`while`ループ。

これらのいずれにも、`label <name>`修飾子を付けてループに記号的な名前を付けることができます。名前付きループは、命令型で制御フローを変更して名前付きループのエントリーや終了から再開するために役立ちます。例えば：

- `continue <name>`でループを再度実行する。
- `break <name>`でループを完全に終了する。

以下の例では、`for`式がテキストの文字を反復処理し、感嘆符に出会うとすぐに反復を放棄します。

```ts
import Debug "mo:base/Debug";
label letters for (c in "ran!!dom".chars()) {
  Debug.print(debug_show(c));
  if (c == '!') { break letters };
  // ...
}
```

### ラベル付き式

`label`には他にも、主流ではないが特定の状況で便利な2つの側面があります：

- `label`は型を持つことができます。
- ループだけでなく、任意の式にラベルを付けることができます。`break`を使うと、その式の評価を短絡させ、即座に結果を返すことができます。これは、`return`を使って関数から早期に終了するのと似ていますが、関数の宣言や呼び出しのオーバーヘッドがありません。

型付きラベルの構文は`label <name> : <type> <expr>`で、これにより任意の式を`break <name> <alt-expr>`構文で終了させ、`<alt-expr>`の値を`<expr>`の値として返すことができ、`<expr>`の評価を短絡させます。

これらの構文を賢く使うことで、プログラマは主なプログラムの論理に集中し、例外的なケースは`break`で処理できます。

```ts
import Text "mo:base/Text";
import Iter "mo:base/Iter";

type Host = Text;
let formInput = "us@dfn";

let address = label exit : ?(Text, Host) {
  let splitted = Text.split(formInput, #char '@');
  let array = Iter.toArray<Text>(splitted);
  if (array.size() != 2) { break exit(null) };
  let account = array[0];
  let host = array[1];
  // if (not (parseHost(host))) { break exit(null) };
  ?(account, host)
}
```

ラベル付きの一般的な式では`continue`は使用できません。型に関しては、`<expr>`と`<alt-expr>`の型はラベルで宣言された`<type>`と一致していなければなりません。ラベルに`<name>`のみを指定した場合、その`<type>`はデフォルトで`unit`（`()`）になります。同様に、`<alt-expr>`なしの`break`は、`unit`（`()`）の値に省略されます。

## オプションブロックとnullブレーク

Motokoでは、`null`値を使うことができ、オプション型`?T`を使用して`null`値が発生する可能性を追跡します。これは、可能な場合には`null`値の使用を避け、必要な場合には`null`値の可能性を考慮することを奨励するためです。Motokoはオプション型を処理するための簡単な構文を提供しています：オプションブロックとnullブレークです。

オプションブロック`do ? <block>`は、ブロック`<block>`が型`T`であるとき、型`?T`の値を生成します。重要なのは、`do ? <block>`内で`<exp> !`というnullブレークが使用されることにより、無関係なオプション型`?U`の式`<exp>`の結果が`null`であるかどうかをテストする点です。結果が`null`であれば、制御は即座に`do ? <block>`を終了し、`null`が返されます。そうでなければ、`<exp>`の結果はオプション値`?v`であり、`<exp> !`の評価がその内容、型`U`の`v`で進行します。

次の例では、自然数から構築された式（除算とゼロテスト）がバリアント型としてエンコードされた簡単な関数を定義します：

<!--
TODO: make interactive
-->

```ts
type Exp = {
  #Lit : Nat;
  #Div : (Exp, Exp);
  #IfZero : (Exp, Exp, Exp);
};

func eval(e : Exp) : ? Nat {
  do ? {
    switch e {
      case (#Lit n) { n };
      case (#Div (e1, e2)) {
        let v1 = eval e1 !;
        let v2 = eval e2 !;
        if (v2 == 0)
          null !
        else v1 / v2
      };
      case (#IfZero (e1, e2, e3)) {
        if (eval e1 ! == 0)
          eval e2 !
        else
          eval e3 !
      };
    };
  };
}
```

0での除算をトラップせずに防ぐために、`eval`関数はオプション結果を返し、失敗時には`null`を返します。

各再帰呼び出しは`null`がないかを確認し、`!`を使って即座に外側の`do ? block`から終了し、結果が`null`であれば関数自体を終了します。

## `loop`による繰り返し

命令型の式を無限に繰り返す最も簡単な方法は、`loop`構文を使うことです：

```ts
loop { <expr1>; <expr2>; ... }
```

このループは`return`または`break`構文でのみ中断できます。

再入条件を付けて、条件付きでループを繰り返すことができます：`loop <body> while <cond>`。

このようなループの本体は、少なくとも1回は実行されます。

## 事前条件付きの`while`ループ

時にはループの各反復を守るためにエントリー条件が必要なことがあります。このような繰り返しには、`while <cond> <body>`形式のループを使用します：

```ts
while (earned < need) { earned += earn() };
```

`loop`とは異なり、`while`ループの本体は実行されない場合があります。

## `for`ループによる反復

同質のコレクションの要素を反復処理するには、`for`ループを使用します。値はイテレータから引き出され、ループパターンに順番にバインドされます。

```ts
let carsInStock = [
  ("Buick", 2020, 23.000),
  ("Toyota", 2019, 17.500),
  ("Audi", 2020, 34.900)
];
var inventory : { var value : Float } = { var value = 0.0 };
for ((model, year, price) in carsInStock.vals()) {
  inventory.value += price;
};
inventory
```

## `for`ループで`range`を使用する

`range`関数は、指定された下限と上限を持つ`Iter<Nat>`型のイテレータを生成します。

次のループ例は、11回の反復で`0`から`10`までの数字を出力します：

```ts
import Iter "mo:base/Iter";
import Debug "mo:base/Debug";
var i = 0;
for (j in Iter.range(0, 10)) {
  Debug.print(debug_show(j));
  assert(j == i);
  i += 1;
};
assert(i == 11);
```

一般的に、`range`関数は自然数のシーケンスに対してイテレータを構築する`class`です。各イテレータは`Iter<Nat>`型を持ちます。

## `revRange`を使用する

`revRange`関数は`Iter<Int>`型のイテレータを構築する`class`です。構造体関数として、次の型を持ちます：

```ts
(upper : Int, lower : Int) -> Iter<Int>
```

`range`とは異なり、`revRange`関数は上限から下限に向かってシーケンスを降順に反復します。

## 特定のデータ構造のイテレータを使用する

多くの組み込みデータ構造には、事前定義されたイテレータがあります。次の表にそれらを示します：

| 型        | 名前                      | イテレータ | 要素                        | 要素型     |
|-----------|---------------------------|------------|-----------------------------|------------|
| `[T]`     | `T`型の配列               | `vals`     | 配列のメンバー             | `T`        |
| `[T]`     | `T`型の配列               | `keys`     | 配列の有効なインデックス   | [`Nat`](../base/Nat.md) |
| `[var T]` | `T`型の可変配列           | `vals`     | 配列のメンバー             | `T`        |
| `[var T]` | `T`型の可変配列           | `keys`     | 配列の有効なインデックス   | [`Nat`](../base/Nat.md) |
| [`Text`](../base/Text.md) | `Text`        | `chars`    | テキストの文字             | `Char`     |
| [`Blob`](../base/Blob.md) | `Blob`        | `vals`     | バイナリデータのバイト       | [`Nat8`](../base/Nat8.md) |

ユーザー定義のデータ構造も自分自身のイテレータを定義できます。`Iter<A>`型に従っている限り、組み込みのものと同じように動作し、通常の`for`ループで消費できます。
