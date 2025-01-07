---
sidebar_position: 4
---

# 引数

引数はアクターの関数に渡され、関数がその入力として使用します。引数は、[`Int`](../base/Int.md)、[`Nat`](../base/Nat.md)、[`Bool`](../base/Bool.md)、[`Text`](../base/Text.md)などの[プリミティブ型](../getting-started/basic-concepts#primitive-values)の値や、タプル、配列、オブジェクトなどの非プリミティブ型の値を使用できます。アクターが引数を受け取る基本的な例を示すために、このページでは複数のテキスト引数を受け取るMotokoアクターの例を使用します。

## 単一のテキスト引数

まず、`location`関数と`city`引数を持つ`name`引数を定義します：

```ts
persistent actor {
  public func location(city : Text) : async Text {
    return "Hello, " # city # "!";
  };
};
```

カニスターが[デプロイ](/docs/current/developer-docs/getting-started/deploy-and-manage)されると、プログラム内で`location`メソッドを呼び出し、次のコマンドを実行して`Text`型の`city`引数を渡すことができます：

```sh
dfx canister call location_hello_backend location "San Francisco"
```

## 複数の引数を渡す

ソースコードを変更して異なる結果を返したい場合があるかもしれません。例えば、`location`関数を変更して複数の都市名を返すようにしたい場合です。

`location`関数を2つの新しい関数で修正します：

```ts
persistent actor {

  public func location(cities : [Text]) : async Text {
    return "Hello, from " # (debug_show cities) # "!";
  };

  public func location_pretty(cities : [Text]) : async Text {
    var str = "Hello from ";
    for (city in cities.vals()) {
        str := str # city # ", ";
    };
    return str # "bon voyage!";
  }
};
```

このコード例で[`Text`](../base/Text.md)が角括弧（`[ ]`）で囲まれていることに気付くかもしれません。`Text`自体は（UTF-8エンコードされた）Unicode文字のシーケンスを表します。型の周りに角括弧を置くと、その型の**配列**を表現します。この文脈では、`[Text]`はテキスト値の配列を示し、プログラムが複数のテキスト値を配列として受け取ることができるようにします。

配列に対して操作を行う関数についての情報は、Motokoベースライブラリの[Arrayモジュール](../base/Array.md)の説明や、**Motokoプログラミング言語リファレンス**を参照してください。配列の使用に焦点を当てた別の例として、[クイックソート](https://github.com/dfinity/examples/tree/master/motoko/quicksort)プロジェクトが[examples](https://github.com/dfinity/examples/)リポジトリにあります。

プログラム内で`location`メソッドを呼び出し、次のコマンドを実行して`city`引数をCandidインターフェース記述構文を使って渡します：

```sh
dfx canister call favorite_cities location '(vec {"San Francisco";"Paris";"Rome"})'
```

このコマンドは、Candidインターフェース記述構文`(vec { val1; val2; val3; })`を使用して、値のベクトルを返します。Candidインターフェース記述言語についての詳細は、[Candid](https://internetcomputer.org/docs/current/developer-docs/smart-contracts/candid/candid-concepts)言語ガイドを参照してください。
