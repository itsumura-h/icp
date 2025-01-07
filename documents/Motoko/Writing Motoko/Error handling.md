---
sidebar_position: 9
---

# エラーハンドリング

Motokoでは、エラーハンドリングを行うための主に3つの方法があります：

-   `null`という情報を提供しない値を使ったオプション型の値。この値は何らかのエラーを示します。

-   エラーに関する詳細情報を提供する記述的な`#err value`を持つ`Result`型のバリアント。

-   非同期コンテキストで例外のようにスローされ、キャッチされる[`Error`](../base/Error.md)型の値。これには数値コードとメッセージが含まれます。

## 例

「完了」マークを付けるための関数を提供するToDoアプリケーションのAPIを作成する場合を考えてみましょう。この単純な例では、`TodoId`オブジェクトを受け取り、そのToDoが開かれてから何秒経過したかを表す[`Int`](../base/Int.md)を返します。この例は、アクター内で非同期値を返す関数として動作します：

```ts
func markDone(id : TodoId) : async Int
```

完全なアプリケーションの例は以下の通りです：

```ts
import Int "mo:base/Int";
import Hash "mo:base/Hash";
import Map "mo:base/HashMap";
import Time "mo:base/Time";
import Result "mo:base/Result";
import Error "mo:base/Error";
```

```ts
  type Time = Int;
  type Seconds = Int;

  func secondsBetween(start : Time, end : Time) : Seconds =
    (end - start) / 1_000_000_000;

  public type TodoId = Nat;

  type Todo = { #todo : { text : Text; opened : Time }; #done : Time };
  type TodoMap = Map.HashMap<TodoId, Todo>;

  var idGen : TodoId = 0;
  transient let todos : TodoMap = Map.HashMap(32, Int.equal, Hash.hash);

  private func nextId() : TodoId {
    let id = idGen;
    idGen += 1;
    id
  };

  /// Creates a new todo and returns its id
  public shared func newTodo(txt : Text) : async TodoId {
    let id = nextId();
    let now = Time.now();
    todos.put(id, #todo({ text = txt; opened = now }));
    id
  };
```

この例では、ToDoを「完了」とマークする際に失敗する条件があります：

-   `id`が存在しないToDoを参照している場合。

-   ToDoがすでに完了としてマークされている場合。

Motokoでこれらのエラーを伝達するさまざまな方法を見て、APIを少しずつ改善していきましょう。

## オプション/結果

Motokoでエラーを伝えるためには、`Option`または`Result`を使用するのが推奨されます。これらは同期および非同期コンテキストの両方で機能し、クライアントに成功ケースだけでなくエラーケースも考慮させることによってAPIの安全性を高めます。例外は予期しないエラーステートを示す場合にのみ使用すべきです。

### `Option`型を使ったエラー報告

値型`A`を返すか、エラーを伝える関数は、オプション型`?A`の値を返し、`null`値を使ってエラーを示すことができます。上記の例では、`markDone`関数が`async ?Seconds`を返します：

定義：

```ts
  public shared func markDoneOption(id : TodoId) : async ?Seconds {
    switch (todos.get(id)) {
      case (?(#todo(todo))) {
        let now = Time.now();
        todos.put(id, #done(now));
        ?(secondsBetween(todo.opened, now))
      };
      case _ { null };
    }
  };
```

呼び出し：

```ts
  public shared func doneTodo2(id : Todo.TodoId) : async Text {
    switch (await Todo.markDoneOption(id)) {
      case null {
        "Something went wrong."
      };
      case (?seconds) {
        "Congrats! That took " # Int.toText(seconds) # " seconds."
      };
    };
  };
```

このアプローチの主な欠点は、すべてのエラーを1つの情報のない`null`値で混同することです。呼び出し元は`Todo`を「完了」にするのがなぜ失敗したのかを知りたいかもしれませんが、その情報はその時点で失われ、ユーザーには「何かがうまくいかなかった」としか伝えることができません。

失敗の原因が1つだけで、その理由が簡単に呼び出し元で判別できる場合にのみ、エラーを示すためにオプション値を返すことが適しています。良い使用例としては、`HashMap`のルックアップが失敗した場合が考えられます。

### `Result`型を使ったエラー報告

`Option`は組み込み型ですが、`Result`は次のようなバリアント型として定義されます：

```ts
type Result<Ok, Err> = { #ok : Ok; #err : Err }
```

2番目の型パラメータ`Err`により、`Result`型ではエラーを記述するための型を選択できます。`markDone`関数がエラーを示すために使う`TodoError`型を定義します：

```ts
  public type TodoError = { #notFound; #alreadyDone : Time };
```

元の例は次のように修正されます：

定義：

```ts
  public shared func markDoneResult(id : TodoId) : async Result.Result<Seconds, TodoError> {
    switch (todos.get(id)) {
      case (?(#todo(todo))) {
        let now = Time.now();
        todos.put(id, #done(now));
        #ok(secondsBetween(todo.opened, now))
      };
      case (?(#done(time))) {
        #err(#alreadyDone(time))
      };
      case null {
        #err(#notFound)
      };
    }
  };
```

呼び出し：

```ts
  public shared func doneTodo3(id : Todo.TodoId) : async Text {
    switch (await Todo.markDoneResult(id)) {
      case (#err(#notFound)) {
        "There is no Todo with that ID."
      };
      case (#err(#alreadyDone(at))) {
        let doneAgo = secondsBetween(at, Time.now());
        "You've already completed this todo " # Int.toText(doneAgo) # " seconds ago."
      };
      case (#ok(seconds)) {
        "Congrats! That took " # Int.toText(seconds) # " seconds."
      };
    };
  };
```

### パターンマッチング

`Option`および`Result`で作業する最初で最も一般的な方法は、パターンマッチングを使用することです。`?Text`型の値を持っている場合、`switch`キーワードを使ってその中身の[`Text`](../base/Text.md)にアクセスできます：

```ts
func greetOptional(optionalName : ?Text) : Text {
  switch (optionalName) {
    case (null) { "No name to be found." };
    case (?name) { "Hello, " # name # "!" };
  }
};
assert(greetOptional(?"Dominic") == "Hello, Dominic!");
assert(greetOptional(null) ==  "No name to be found");
```

Motokoでは、値が`null`である可能性がある場合、オプション値にアクセスする際にはそのケースを考慮しなければなりません。

`Result`の場合もパターンマッチングを使用できますが、`#err`ケースで`null`ではなく、情報を提供する値が得られる点が異なります：

```ts
func greetOptional(optionalName : ?Text) : Text {
  switch (optionalName) {
    case (null) { "No name to be found." };
    case (?name) { "Hello, " # name # "!" };
  }
};
assert(greetOptional(?"Dominic") == "Hello, Dominic!");
assert(greetOptional(null) ==  "No name to be found");
```

### 高階関数

パターンマッチングは、特に複数のオプション値を扱う場合、冗長で面倒になることがあります。[base](https://github.com/dfinity/motoko-base)ライブラリは、`Option`および`Result`モジュールからエラーハンドリングの利便性を高める高階関数のコレクションを公開しています。

`Option`と`Result`の間で移動したい場合があります。`HashMap`のルックアップは失敗時に`null`を返しますが、呼び出し元がより多くのコンテキストを持っており、その失敗を意味のある`Result`に変換できる場合です。逆に、`Result`が提供する追加情報は必要なく、すべての`#err`ケースを`null`に変換したい場合もあります。このような場合、[base](https://github.com/dfinity/motoko-base)は、`Result`モジュール内の`fromOption`および`toOption`関数を提供しています。

## 非同期エラー

Motokoでエラーを処理する最後の方法は、非同期[`Error`](../base/Error.md)ハンドリングです。これは、他の言語でおなじみの例外ハンドリングの制限された形式です。Motokoのエラー値は、非同期コンテキストでのみスローおよびキャッチ可能です。通常、`shared`関数や`async`式の本体内で使用されます。非`shared`関数では構造化されたエラーハンドリングを行うことはできません。これにより、`throw`を使って[`Error`](../base/Error.md)型のエラー値で共有関数から抜け出し、別のアクター上の共有関数を呼び出すコードを`try`ブロックで処理できます。このワークフローでは、エラーは`Error`型の結果として`catch`できますが、非同期コンテキスト外ではこれらのエラーハンドリング構文は使用できません。

非同期[`Error`](../base/Error.md)は、通常、回復不可能で予期しない失敗を示すためにのみ使用すべきです。APIの多くの消費者がそのエラーを処理できないときです。失敗を呼び出し元が処理すべき場合は、`Result`を返すことでその意図を明示的に示すべきです。ここでは、`markDone`の例に例外を使用したコードを示します：

定義：

```ts
  public shared func markDoneException(id : TodoId) : async Seconds {
    switch (todos.get(id)) {
      case (?(#todo(todo))) {
        let now = Time.now();
        todos.put(id, #done(now));
        secondsBetween(todo.opened, now)
      };
      case (?(#done _)) {
        throw Error.reject("Already done")
      };
      case null {
        throw Error.reject("Not Found")
      };
    }
  };
```

呼び出し：

```ts
  public shared func doneTodo4(id : Todo.TodoId) : async Text {
    try {
      let seconds = await Todo.markDoneException(id);
      "Congrats! That took " # Int.toText(seconds) # " seconds.";
    } catch _ {
      "Something went wrong.";
    }
  };
```

## `try/finally`の使用

`finally`節は、`try/catch`エラーハンドリング式内で使用され、制御フロー式のクリーンアップ、リソースの解放、または一時的な状態変更のロールバックを行います。`finally`節はオプションであり、使用される場合、`catch`節は省略可能です。`try`ブロックからの未キャッチのエラーは、`finally`ブロックが実行された後に伝播され

ます。

:::info

`try/finally`は、`moc` `v0.12.0`以降、`dfx` `v0.24.0`以降でサポートされています。

:::

`try/finally`は、非同期式内または`shared`関数の本体内で使用しなければなりません。`try/finally`を使用する前に、この構文の[セキュリティベストプラクティス](https://internetcomputer.org/docs/current/developer-docs/security/security-best-practices/inter-canister-calls#recommendation)を確認してください。

```ts
import Text "mo:base/Text";
import Debug "mo:base/Debug";

persistent actor {

  public func tryFunction() {
   try {
      func greetOptional(optionalName : ?Text) : Text =
        switch optionalName {
          case null { "No name to be found." };
          case (?name) { "Hello, " # name # "!" };
        };
       assert greetOptional(?"Motoko") == "Motoko";
    } finally {
       Debug.print("Finally block executed");
    }
  }

}
```

`try`ブロック内ではエラーをスローする可能性のあるコードを含めます。`finally`ブロック内では、エラーがスローされてもされなくても実行されるべきコードを含めます。`finally`ブロック内のコードは、トラップせずに迅速に終了するべきです。`finally`ブロックがトラップすると、将来のカニスターのアップグレードが妨げられることがあります。

[`try/finally`](https://internetcomputer.org/docs/current/motoko/main/reference/language-manual#try)の詳細を学ぶ。

### エラーを適切に処理しない方法

エラーを報告する一般的に良くない方法は、センチネル値を使用することです。例えば、`markDone`関数で何かが失敗したことを示すために`-1`を使用するとしましょう。その場合、呼び出し元はこの特殊な値と返り値を比較し、エラーを報告しなければなりません。そのエラー条件をチェックせずにコード内でその値を使用し続けてしまうことが容易にありえます。これにより、エラー検出が遅れるか、見逃される可能性があり、強く避けるべきです。

定義：

```ts
  public shared func markDoneBad(id : TodoId) : async Seconds {
    switch (todos.get(id)) {
      case (?(#todo(todo))) {
        let now = Time.now();
        todos.put(id, #done(now));
        secondsBetween(todo.opened, now)
      };
      case _ { -1 };
    }
  };
```

呼び出し：

```ts
  public shared func doneTodo1(id : Todo.TodoId) : async Text {
    let seconds = await Todo.markDoneBad(id);
    if (seconds != -1) {
      "Congrats! That took " # Int.toText(seconds) # " seconds.";
    } else {
      "Something went wrong.";
    };
  };
```
