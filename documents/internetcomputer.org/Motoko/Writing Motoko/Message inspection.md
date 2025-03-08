---
sidebar_position: 14
---

# メッセージの検査

ICPでは、カニスターはHTTPインターフェースを通じて送信されたイングレスメッセージを選択的に検査し、そのメッセージを受け入れるか拒否するかを決定することができます。

> カニスターは、イングレスメッセージを実行する前に検査できます。ICPがユーザーからの更新呼び出しを受け取ると、ICPは`canister_inspect_message`メソッドを使用してメッセージが受け入れられるかどうかを判断します。カニスターが空である場合（つまりWasmモジュールがない場合）、イングレスメッセージは拒否されます。カニスターが空でなく、`canister_inspect_message`を実装していない場合、イングレスメッセージは受け入れられます。
>
> `canister_inspect_message`内で、カニスターは`ic0.accept_message : () → ()`を呼び出すことでメッセージを受け入れることができます。この関数は二度呼び出されるとトラップします。`canister_inspect_message`でカニスターがトラップした場合や`ic0.accept_message`を呼び出さなかった場合、アクセスは拒否されます。
>
> `canister_inspect_message`は、HTTPクエリ呼び出し、カニスター間呼び出し、または管理カニスターへの呼び出しには呼び出されません。
>
> — [ICインターフェース仕様書](https://internetcomputer.org/docs/current/references/ic-interface-spec/#system-api-inspect-message)

メッセージの検査は、不要な無料呼び出しを通じてカニスターのサイクルを消耗させることを目的としたサービス拒否（DoS）攻撃を緩和します。

## Motokoでのメッセージ検査

Motokoでは、アクターは特定の`system`関数である`inspect`を宣言することでイングレスメッセージを検査し、受け入れるか拒否するかを選択できます。この関数は、メッセージ属性のレコードを受け取り、`Bool`型を返すことで、メッセージを受け入れるか拒否するかを示します。`true`または`false`を返します。

この関数は、各イングレスメッセージに対してシステムによって呼び出されます。クエリと同様に、呼び出しの副作用は破棄され、一時的なものです。何らかのエラーによるトラップが発生した場合、その結果はメッセージの拒否と同じになります。

他のシステム関数とは異なり、`inspect`の引数型は囲んでいるアクターのインターフェースに依存します。特に、`inspect`の正式な引数は次のフィールドを持つレコードです：

- `caller : Principal`: メッセージの呼び出し元のプリンシパル
- `arg : Blob`: メッセージ引数の生のバイナリ内容
- `msg : <variant>`: デコーディング関数のバリアント、`<variant> == {…​; #<id>: () → T; …​}` はアクターの各共有関数`<id>`に対して1つのバリアントを含みます。このバリアントのタグは呼び出す関数を識別し、その引数は関数がデコードした呼び出し引数を値`T`として返します。

バリアントを使用することで、デコーディング関数の戻り値型`T`は、引数型`T`に合わせて変動することができます。

バリアントの引数は関数であり、メッセージのデコードコストを回避できます。

サブタイピングを利用することで、正式な引数は必要ないフィールドを省略したり、特定の共有関数の引数を選択的に無視したりできます。例えば、関数名だけでディスパッチし、実際の引数を検査しないことができます。

:::note

`shared query`関数は、通常のHTTP更新呼び出しを使って認証済みの応答を得ることができます。これが、バリアント型に`shared query`関数が含まれる理由です。

`shared composite query`関数は更新呼び出しとして呼び出すことができません。それは、速いが未認証のHTTPクエリ呼び出しのみで呼び出すことができます。

そのため、`inspect`バリアント型には`shared query`関数が含まれますが、`shared composite query`関数は含まれません。

:::

:::danger

`inspect`システムフィールドを宣言しないアクターは、すべてのイングレスメッセージを単純に受け入れます。

:::

:::danger

システム関数`inspect`は、決定的なアクセス制御に使用すべきではありません。なぜなら、`inspect`は単一のレプリカで実行され、完全なコンセンサスを経ないからです。その結果は悪意のある境界ノードによって偽造される可能性があります。また、`inspect`はカニスター間の呼び出しには呼び出されません。信頼できるアクセス制御のチェックは、`inspect`で保護された`shared`関数内でのみ行うことができます。詳細については、[カニスター開発のセキュリティベストプラクティス](https://internetcomputer.org/docs/current/developer-docs/security/rust-canister-development-security-best-practices#do-not-rely-on-ingress-message-inspection)を参照してください。

:::

## 例

メソッド検査の簡単な例として、いくつかのメッセージを詳細に検査し、他のメッセージは表面的にのみ検査するカウンターアクターを考えてみましょう：

```ts file=../examples/InspectFull.mo
import Principal = "mo:base/Principal";

persistent actor {

   var c = 0;

   public func inc() : async () { c += 1 };
   public func set(n : Nat) : async () { c := n };
   public query func read() : async Nat { c };
   public func reset() : () { c := 0 }; // oneway

   system func inspect(
     {
       caller : Principal;
       arg : Blob;
       msg : {
         #inc : () -> ();
         #set : () -> Nat;
         #read : () -> ();
         #reset : () -> ();
       }
     }) : Bool {
    if (Principal.isAnonymous(caller)) return false;
    if (arg.size() > 512) return false;
    switch (msg) {
      case (#inc _) { true };
      case (#set n) { n() != 13 };
      case (#read _) { true };
      case (#reset _) { false };
    }
  }
};
```

サブタイピングにより、以下のように引数の詳細度が増す順に、`inspect`の定義はすべて合法です。

すべてのイングレスメッセージを一律に拒否し、さらに情報を無視：

```ts no-repl file=../examples/InspectNone.mo#L10-L10
   system func inspect({}) : Bool { false }
```

匿名の呼び出しを拒否：

```ts no-repl file=../examples/InspectCaller.mo#L12-L14
   system func inspect({ caller : Principal }) : Bool {
     not (Principal.isAnonymous(caller));
   }
```

`arg`の生のバイトサイズに基づいて、大きなメッセージを拒否（CandidバイナリブロブからMotoko値にデコードする前）：

```ts no-repl file=../examples/InspectArg.mo#L10-L13
  system func inspect({ arg : Blob }) : Bool {
    arg.size() <= 512;
  }
```

名前のみでメッセージを拒否し、メッセージ引数を無視。ここではメッセージ引数のバリアントとして`Any`型を使用しています：

```ts no-repl file=../examples/InspectName.mo#L10-L23
  system func inspect(
    {
      msg : {
        #inc : Any;
        #set : Any;
        #read : Any;
        #reset : Any;
      }
    }) : Bool {
    switch (msg) {
      case ((#set _) or (#reset _)) { false };
      case _ { true }; // allow inc and read
    }
  }
```

前述の3つを組み合わせ、いくつかのバリアントの引数型を指定し、他の引数は`Any`型で無視し、パターンマッチングを使用して同じケースをまとめる：

```ts no-repl file=../examples/InspectMixed.mo#L12-L30
  system func inspect(
    {
      caller : Principal;
      arg : Blob;
      msg : {
        #inc : Any;
        #set : () -> Nat;
        #read : Any;
        #reset : Any;
      }
    }) : Bool {
    if (Principal.isAnonymous(caller)) return false;
    if (arg.size() > 512) return false;
    switch (msg) {
      case (#set n) { n() != 13 };
      case (#reset _) { false };
      case _ { true }; // allow inc and read
    }
  }
```

## `inspect`の執筆に関するヒント

アクターのすべての共有関数がすでに実装されている後で`inspect`を実装するのは面倒です。各共有関数に対して正しく型指定されたバリアントを宣言する必要があります。簡単なコツとしては、まず`()`引数で関数を誤って実装し、コードをコンパイルしてから、コンパイラのエラーメッセージを使用して必要な引数型を取得することです。

例えば、前のセクションのアクターで誤って宣言すると、コンパイラが期待される型を報告し、それをコードに貼り付けることができます：

```ts no-repl file=../examples/InspectTrick.mo#L11-L13
  system func inspect() : Bool {
     false
  }
```

```ts no-repl
Inspect.mo:12.4-14.5: 型エラー [M0127]、システム関数inspectが型
  () -> Bool
で宣言されていますが、期待される型は
  {
    arg : Blob;
    caller : Principal;
    msg :
      {
        #inc : () -> ();
        #read : () -> ();
        #reset : () -> ();
        #set : () -> Nat
      }
  } -> Bool
```

<img src="https://github.com/user-attachments/assets/844ca364-4d71-42b3-aaec-4a6c3509ee2e" alt="Logo" width="150" height="150" />
