---
sidebar_position: 28
---

# 非同期コードの抽象化

関数は抽象化のメカニズムであり、計算に名前を付け、その関数をコード内の異なる場所で単に呼び出すことによって再利用することができます。関数がパラメータを取る場合、異なる引数を提供することで、異なる呼び出し元に合わせた計算を行うことができます。

プログラマはよく、共通のコードパターンを1つの再利用可能な関数にリファクタリングしてコードを改善します。

Motoko では、メッセージ送信や未来（Future）の待機といった非同期操作を含むコードをリファクタリングしたい場合があります。Motoko の型システムは、通常の関数ではこれを行えないようにしています。なぜなら、通常の関数はメッセージを送信したり、待機したりすることが許可されていないからです。しかし、非同期コードを含むローカルな非同期関数を定義し、その関数を呼び出すことでパターンのすべての出現を置き換えることができます。この呼び出しは未来を返すため、各呼び出しはその未来の結果を抽出するために `await` で囲む必要があります。

これにはオーバーヘッドや落とし穴がいくつかあります：
- 関数を呼び出すたびに、アクター自身に対して追加のメッセージ送信が発生します。
- 各呼び出しは `await` される必要があり、それにより抽象化されたコードのコストが大幅に増加します。
- 各 `await` は `await` 元の実行を停止させ、返信が利用可能になるまで待機し、他の並行メッセージの実行と干渉しやすくなります。

以下のコードは、リモートカニスターにログを記録する例です。

```ts
persistent actor class (Logger : actor { log : Text -> async () }) {

  var logging = true;

  func doStuff() : async () {
    // 処理を行う
    if (logging) { await Logger.log("stuff") };
    // さらに処理を行う
    if (logging) { await Logger.log("more stuff") };
  }
}
```

ログ記録ロジックの繰り返しを避けるため、`maybeLog` という補助関数を使ってリファクタリングすると良いでしょう。
`maybeLog` 関数は、`Logger` カニスターとの通信にメッセージ送信を伴うため、非同期関数でなければなりません。

```ts
persistent actor class (Logger : actor { log : Text -> async () }) {

  var logging = true;

  func maybeLog(msg : Text) : async () {
    if (logging) { await Logger.log(msg) };
  };

  func doStuff() : async () {
    // 処理を行う
    await maybeLog("stuff");
    // さらに処理を行う
    await maybeLog("more stuff");
  }
}
```

このコードは型チェックされ、実行されますが、`doStuff()` のコードは元のコードよりも効率が悪くなります。なぜなら、`maybeLog` 関数の呼び出しごとに `await` が追加され、`logging` フラグが `false` の場合でも `doStuff()` の実行が一時停止されるからです。
このコードのセマンティクスもわずかに異なります。なぜなら、`logging` 変数の値が `maybeLog` の呼び出しとその本体の実行の間に変更される可能性があるからです。

より安全なリファクタリングは、各呼び出しで `logging` 変数の現在の状態を渡す方法です：

```ts
persistent actor class (Logger : actor { log : Text -> async () }) {

  var logging = true;

  func maybeLog(log : Bool, msg : Text) : async () {
    if (log) { await Logger.log(msg) };
  };

  func doStuff() : async () {
    // 処理を行う
    await maybeLog(logging, "stuff");
    // さらに処理を行う
    await maybeLog(logging, "more stuff");
  }
}
```

## 計算型

追加の `await` のオーバーヘッドやリスクを避けるために、Motoko は計算型 `async* T` を提供しています。これは、未来型 `async T` と同様に非同期タスクを抽象化できます。

`async` 式が未来（非同期タスクの実行をスケジュールする）を作成するのと同じように、`async*` 式は計算を作成するために使用されます（その本体の実行を遅延させることによって）。
`await` が未来の結果を消費するのと似て、`await*` は計算の結果を生成します（その本体の再実行を要求することによって）。

型の観点から見ると、未来と計算は非常に似ています。異なるのは動的挙動です：未来はスケジュールされた非同期タスクの結果を保持する状態を持つオブジェクトであり、計算はタスクを記述する単なる不活性な値です。

未来に対する `await` と異なり、計算に対する `await*` は `await` 元を一時停止させることはなく、通常の関数呼び出しのように計算を即座に実行します。
つまり、`async*` 値を `await` することは、その実行を一時停止させるだけであり、計算の本体が適切な `await` を行う場合にのみ非同期に完了します。
これらの式に付けられた `*` は、計算が0回以上の通常の `await` 式を含む可能性があり、したがって他のメッセージの実行と交互に実行される可能性があることを示しています。

`async*` 値を作成するには、単に `async*` 式を使えばよいですが、より典型的には、`async*` 型を返すローカル関数を宣言します。

`async*` 計算の結果を計算するには、`await*` を使います。

これが元のクラスを計算を使ってより明確で効率的に、そして同じ意味を持つようにリファクタリングした方法です：

```ts
persistent actor class (Logger : actor { log : Text -> async () }) {

  var logging = true;

  func maybeLog(msg : Text) : async* () {
    if (logging) { await Logger.log(msg) };
  };

  func doStuff() : async () {
    // 処理を行う
    await* maybeLog("stuff");
    // さらに処理を行う
    await* maybeLog("more stuff");
  }
}
```

`async` と `async*` 式の大きな違いの1つは、前者が強制的に実行されるのに対し、後者は遅延実行されるということです。
つまり、`maybeLog` の非同期バージョンを呼び出すと、その本体は即座に実行されます。たとえその結果（未来）が `await` されなくても、です。
同じ未来を再度 `await` しても、常に最初の結果が得られます：メッセージは一度だけ実行されます。

一方、`async*` バージョンの `maybeLog` を呼び出すと、結果が `await*` されない限り、何も実行されません。`await*` で同じ計算を何度も `await` すると、その計算は毎回繰り返し実行されます。

別の例として、`clap` 関数を定義し、サイドエフェクトとして「clap」を表示する場合を考えます：

```ts no-repl
import Debug "mo:base/Debug"
func clap() { Debug.print("clap") }
```

このコードは未来を使うと1回だけ「clap」を表示します：

```ts no-repl
let future = async { clap() };
```

何度 `future` を `await` しても結果は変わりません。例えば：

```ts no-repl
let future = async { clap() };
await future;
await future;
```

一方、計算を使うと、次の定義では単独では効果がありません：

```ts no-repl
let computation = async* { clap() };
```

しかし、次の例では「clap」が2回表示されます：

```ts no-repl
let computation = async* { clap() };
await* computation;
await* computation;
```

:::danger

`async*`/`await*` を使用する際は注意が必要です。通常の `await` は Motoko のコミットポイントです：すべての状態変更は一時停止前にコミットされます。
一方、`await*` はコミットポイントではありません（その本体がまったく `await` しないか、いずれかの不確定な時点でコミットする可能性があるため）。
これは、`await*` の計算内でトラップが発生した場合、`await*` 自体ではなく、`await*` より前の最後のコミットポイントまでアクターの状態がロールバックされる可能性があることを意味します。

:::

`async*` 型、`async*` 式、`await*` 式の詳細については、[言語マニュアル](../reference/language-manual#async-type-1)、[async* 式](../reference/language-manual#async-1)、[await* 式](../reference/language

-manual#await-1)を参照してください。

## 計算のための Mops パッケージ

- [`star`](https://mops.one/star): `async*` 関数を使用して非同期の動作とトラップを処理するために使用されます。

<img src="https://github.com/user-attachments/assets/844ca364-4d71-42b3-aaec-4a6c3509ee2e" alt="Logo" width="150" height="150" />
