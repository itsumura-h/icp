---
sidebar_position: 28
---

# Candid シリアライゼーション

Candid は、インターネットコンピュータプロトコル専用に設計されたインターフェース記述言語およびシリアライゼーションフォーマットです。これは、異なるプログラミング言語で実装されたサービスやカニスターのスマートコントラクト間でシームレスな通信を可能にする重要なコンポーネントです。

Candid の基本的な役割は、言語に依存しない方法でデータを記述し、転送することです。強い型付けにより、さまざまなサービスや言語間でのデータ解釈の正確性が保証されます。この型安全性は、データのエンコーディング用に効率的なバイナリ形式を補完しており、ネットワークでの転送に最適です。

Motoko の文脈では、Candid は言語に深く統合されています。Motoko はカニスターのスマートコントラクト用の Candid インターフェースを自動的に生成し、データを Candid 形式で簡単にシリアライズおよびデシリアライズするための組み込み関数 `to_candid` と `from_candid` を提供します。

広い意味で、Candid はカニスター間の標準通信プロトコルとして機能します。あるカニスターが別のカニスターを呼び出すと、引数は Candid 形式にシリアライズされて送信され、受信側のカニスターでデシリアライズされます。この標準化により、Motoko や Rust で書かれたバックエンドカニスターと簡単にやり取りできるフロントエンドを JavaScript などの言語で作成することが可能になります。

重要なのは、Candid の設計がカニスターインターフェースの後方互換性のあるアップグレードを可能にすることです。この機能は、インターネットコンピュータ上の長期間運用されるアプリケーションにとって、サービスの進化を促進する重要な側面です。

## 明示的な Candid シリアライゼーション

Motoko の `to_candid` と `from_candid` 演算子を使用すると、Candid でエンコードされたデータを扱うことができます。

`to_candid (<exp1>, ..., <expn>)` は Motoko の値のシーケンスをシリアライズし、Candid バイナリエンコーディングを含む `Blob` を返します。

例えば：

```ts no-repl
let encoding : Blob = to_candid ("dogs", #are, ['g', 'r', 'e', 'a', 't']);
```

`from_candid <exp>` は、Candid データを含む `Blob` をデシリアライズして Motoko の値に戻します。

```ts no-repl
 let ?(t, v, cs) = from_candid encoding : ?(Text, {#are; #are_not}, [Char]);
```

`from_candid` は、その引数が有効な Candid データを含まない `Blob` の場合、トラップを発生させます。デシリアライズは、エンコードされた値が期待される Candid 型でない場合に失敗する可能性があるため、`from_candid` はオプション型の値を返します。`null` はエンコードが正しく形成されているが、間違った Candid 型であることを示し、`?v` はデコードされた値を示します。`from_candid` はそのオプションの結果型が他のコードで決定されるコンテキストでのみ使用でき、型注釈が必要な場合があります。

例えば、デコードされた値の期待型を指定しないこのコードはコンパイラに拒否されます：

```ts no-repl
let ?(t, v, cs) = from_candid encoding;
```

`to_candid` と `from_candid` 演算子は、言語に組み込まれたキーワードであり、ほとんどの一般的なユースケースを自動的に処理します。これらの演算子は、型安全性と適切なデータエンコーディングを確保し、開発者が Candid シリアライゼーションの複雑さを手動で処理する必要をなくします。

:::danger

`to_candid` は引数の有効な Candid エンコーディングを返しますが、実際には同じ値に対して異なる Candid エンコーディング（およびそれに対応する `Blob`）が存在することがあります。したがって、`to_candid` が常に同じ `Blob` を返す保証はありません。同じ引数であっても異なる `Blob` を返す可能性があるため、これらの `Blob` を使用して値の等価性を比較したり、Candid エンコーディングのハッシュを計算したりしないようにしてください。値のハッシュは一意であるべきですが、複数の Candid エンコーディングから計算した場合、一意でない可能性があります。

:::

詳細については、[言語マニュアル](../reference/language-manual#candid_serialization)を参照してください。

## 動的呼び出し

ほとんどのユーザーは `to_candid` や `from_candid` を使用する必要はありません。これらの操作が有用なのは、`ExperimentalInternetComputer` ベースライブラリの `call` 関数を使ってカニスターのメソッドを動的に呼び出す場合です。

ICP 上のほとんどのカニスターは Candid を使用しますが、ICP によって強制されているわけではありません。プロトコルレベルでは、カニスターは生のバイナリデータで通信します。Candid は、そのデータの共通の解釈方法であり、異なる言語で書かれたカニスター同士の相互運用を可能にします。

`call` 関数は、カニスターのプリンシパル、メソッド名（テキストとして）、および生のバイナリ `Blob` を受け取り、呼び出しの結果を生のバイナリ `Blob` として含むフューチャーを返します。

動的呼び出しは、特に複雑なインターフェースや非標準的なインターフェースを持つカニスターやサービスと作業する場合や、呼び出しプロセスを細かく制御する必要がある場合に便利です。しかし、バイナリエンコーディングとデコーディングを手動で処理する必要があり、Motoko が提供する高レベルの抽象化を使うよりもエラーが発生しやすくなります。

サービスが Candid を使用し、呼び出したいメソッドの型がわかっている場合は、`to_candid` と `from_candid` を使ってバイナリ形式を扱うことができます。

通常は、呼び出しの引数を準備するために `to_candid` を使用し、その結果を処理するために `from_candid` を使用します。

この例では、インポートした `call` 関数を使用してアクターに対する動的呼び出しを行っています：

```ts no-repl
import Principal "mo:base/Principal";
import {call} "mo:base/ExperimentalInternetComputer";

persistent actor This {

   public func concat(ts : [Text]) : async Text {
      var r = "";
      for (t in ts.vals()) { r #= t };
      r
   };

   public func test() : async Text {
       let arguments = to_candid (["a", "b", "c"]);
       let results = await call(Principal.fromActor(This), "concat", arguments);
       let ?t = from_candid(results) : ?Text;
       t
   }

}
```

動的呼び出しは柔軟性を提供しますが、慎重に使用するべきです。ほとんどの場合、Motoko における標準的なカニスター間呼び出しメカニズムと自動的な Candid 処理が、安全で便利なカニスター間のやり取り方法を提供します。

## リソース

Candid に関する詳細情報については、以下のドキュメントを参照してください：

- [Candid UI](/docs/current/developer-docs/smart-contracts/candid).
- [Candidとは？](/docs/current/developer-docs/smart-contracts/candid/candid-concepts).
- [Candidの使用](/docs/current/developer-docs/smart-contracts/candid/candid-howto).
- [Candid仕様](https://github.com/dfinity/candid/blob/master/spec/Candid.md).

<img src="https://github.com/user-attachments/assets/844ca364-4d71-42b3-aaec-4a6c3509ee2e" alt="Logo" width="150" height="150" />
