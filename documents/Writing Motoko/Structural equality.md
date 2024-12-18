---
sidebar_position: 25
---

# 構造的等価性

等価性（`==`）およびその拡張である不等価性（`!=`）は **構造的** です。2つの値、`a` と `b` が等しい場合、`a == b` です。これらの値は、メモリ内での物理的な表現や識別に関係なく、その内容が等しいと見なされます。

例えば、文字列 `"hello world"` と `"hello " # "world"` は等しいと見なされます。これらはメモリ内で異なるオブジェクトとして表現されている可能性が高いですが、それでも等価と見なされます。

等価性は、`shared` 型または次の内容を含まない型にのみ定義されています：

- 可変フィールド。
- 可変配列。
- 非共有関数。
- ジェネリック型のコンポーネント。

例えば、オブジェクトの配列を比較することができます：

```ts run
let a = [ { x = 10 }, { x = 20 } ];
let b = [ { x = 10 }, { x = 20 } ];
a == b;
```

重要なのは、これが参照による比較ではなく、値による比較であるということです。

## サブタイプ

等価性はサブタイプを尊重します。たとえば、`{ x = 10 } == { x = 10; y = 20 }` は `true` を返します。

サブタイプを考慮するために、異なる型の2つの値は、最も特定的な共通スーパータイプで等しい場合に等価と見なされます。つまり、共通の構造に一致している必要があります。このような場合に微妙な予期しない動作を引き起こす可能性があるとき、コンパイラは警告を出します。

例えば、`{ x = 10 } == { y = 20 }` は `true` を返します。これは、2つの値が空のレコード型で比較されるからです。これは意図していない結果である可能性が高いため、コンパイラはここで警告を出します。

```ts run
{ x = 10 } == { y = 20 };
```

## ジェネリック型

ジェネリック型変数が `shared` であると宣言することはできないため、等価性は非ジェネリック型に対してのみ使用できます。例えば、次の式は警告を生成します：

```ts run
func eq<A>(a : A, b : A) : Bool = a == b;
```

`Any` 型でこれら2つを比較することは、引数に関係なく `true` を返すため、期待通りには動作しません。

この制限に遭遇した場合、比較関数の型 `(A, A) -> Bool` を引数として受け取り、それを使って値を比較する方法を取るべきです。

例えば、リストのメンバーシップテストを見てみましょう。この最初の実装は **動作しません**：

```ts run
import List "mo:base/List";

func contains<A>(element : A, list : List.List<A>) : Bool {
  switch list {
    case (?(head, tail))
      element == head or contains(element, tail);
    case null false;
  }
};

assert(not contains(1, ?(0, null)));
```

このアサーションはトラップします。なぜなら、コンパイラが型 `A` を `Any` として比較するため、常に `true` を返してしまうからです。リストに少なくとも1つの要素がある限り、このバージョンの `contains` は常に `true` を返します。

次の2番目の実装では、比較関数を明示的に受け取る方法を示しています：

```ts run
import List "mo:base/List";
import Nat "mo:base/Nat";

func contains<A>(eqA : (A, A) -> Bool, element : A, list : List.List<A>) : Bool {
  switch list {
    case (?(head, tail))
      eqA(element, head) or contains(eqA, element, tail);
    case null false;
  }
};

assert(not contains(Nat.equal, 1, ?(0, null)));
```

<img src="https://github.com/user-attachments/assets/844ca364-4d71-42b3-aaec-4a6c3509ee2e" alt="Logo" width="150" height="150" />
