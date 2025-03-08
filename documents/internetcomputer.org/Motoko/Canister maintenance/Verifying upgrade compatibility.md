---
sidebar_position: 4
---

# アップグレード互換性の確認

カニスターをアップグレードする際、以下の点を確認することが重要です：

-   安定宣言に互換性のない変更を導入していないこと。
-   Candid インターフェースの変更によってクライアントが壊れないこと。

`dfx` はこれらのプロパティをアップグレード前に静的にチェックします。
さらに、[強化された直交的永続性](orthogonal-persistence/enhanced.md)により、Motoko は安定宣言に互換性のない変更を拒否します。

## アップグレードの例

以下は、状態を持つカウンターを宣言する簡単な例です：

```ts no-repl file=../examples/count-v0.mo
import Debug "mo:base/Debug";

actor Counter_v0 {
  var state : Nat = 0; // implicitly `transient`

  public func increment() : async () {
    state += 1;
    Debug.print(debug_show (state));
  };
};
```

重要な点は、この例では、カウンターがアップグレードされると、その状態が失われることです。
これは、アクター変数がデフォルトで `transient` であるため、アップグレード時に再初期化されるからです。
上記のアクターは、`transient` 宣言を使用するのと同じです：

```ts no-repl file=../examples/count-v0transient.mo
import Debug "mo:base/Debug";

actor Counter_v0 {
  transient var state : Nat = 0;

  public func increment() : async () {
    state += 1;
    Debug.print(debug_show (state));
  };
};
```

これを修正するために、アップグレードを通して保持される `stable` 変数を宣言できます：

```ts no-repl file=../examples/count-v1stable.mo
import Debug "mo:base/Debug";

actor Counter_v1 {
  stable var state : Nat = 0;

  public func increment() : async () {
    state += 1;
    Debug.print(debug_show (state));
  };
};
```

すべての宣言に対して `stable` をデフォルトにし、`transient` をオプションにしたい場合は、アクター宣言の前に `persistent` キーワードを付けます。

```ts no-repl file=../examples/count-v1.mo
import Debug "mo:base/Debug";

persistent actor Counter_v1 {
  var state : Nat = 0; // implicitly `stable`

  public func increment() : async () {
    state += 1;
    Debug.print(debug_show (state));
  };
};
```

もし `state` 変数が `stable` として宣言されていなかった場合、明示的に `transient` を指定するか、`persistent` をアクターキーワードに適用することで、`state` はアップグレード時に `0` から再スタートします。

## 安定宣言の進化

カウンターを `Nat` から `Int` に変更するのは、安定宣言において互換性のある変更です。カウンターの値はアップグレード中に保持されます。

```ts no-repl file=../examples/count-v2.mo
import Debug "mo:base/Debug";

persistent actor Counter_v2 {
  var state : Int = 0; // implicitly `stable`

  public func increment() : async () {
    state += 1;
    Debug.print(debug_show (state));
  };
};
```

## 安定型のシグネチャ

安定型シグネチャは、Motoko アクターの安定した内容を記述します。
これをアクターの内部インターフェースとして考えることができ、将来のアップグレードに提示されます。

例えば、`v1` の安定型：

```ts no-repl file=../examples/count-v1.most
actor {
  stable var state : Nat
};
```

`v1` から `v2` へのアップグレードでは、[`Nat`](../base/Int.md) を [`Int`](../base/Nat.md) として消費します。これは、`Int <: Nat` であるため有効です。

```ts no-repl file=../examples/count-v2.most
actor {
  stable var state : Int
};
```

## Candid インターフェースの進化

インターフェースのこの拡張では、古いクライアントは引き続き動作し、新しいクライアントには `decrement` 関数や `read` クエリのような新機能が追加されます。

```ts no-repl file=../examples/count-v3.mo
persistent actor Counter_v3 {
  var state : Int = 0; // implicitly `stable`

  public func increment() : async () {
    state += 1;
  };

  public func decrement() : async () {
    state -= 1;
  };

  public query func read() : async Int {
    return state;
  };
};
```

## 二重インターフェースの進化

アップグレードが安全であるためには、Candid インターフェースと安定型シグネチャの両方が互換性を保っている必要があります：
* 各安定変数は、新たに宣言されるか、削除されるか、その古い型のスーパータイプで再宣言されなければなりません。
* Candid インターフェースはサブタイプに進化します。

以下はカウンターの例の4つのバージョンです：

バージョン `v0` の Candid インターフェース `v0.did` と安定型インターフェース `v0.most`：

```ts file=../examples/count-v0.did
service : {
  increment : () -> ();
};
```

```ts no-repl file=../examples/count-v0.most
actor {  
};
```

バージョン `v1` の Candid インターフェース `v1.did` と安定型インターフェース `v1.most`：

``` candid file=../examples/count-v1.did
service : {
  increment : () -> ();
};
```

```ts no-repl file=../examples/count-v1.most
actor {
  stable var state : Nat
};
```

バージョン `v2` の Candid インターフェース `v2.did` と安定型インターフェース `v2.most`：

``` candid file=../examples/count-v2.did
service : {
  increment : () -> ();
};
```

```ts no-repl file=../examples/count-v2.most
actor {
  stable var state : Int
};
```

バージョン `v3` の Candid インターフェース `v3.did` と安定型インターフェース `v3.most`：

``` candid file=../examples/count-v3.did
service : {
  increment : () -> ();
  decrement : () -> ();
  read : () -> (int) query;
};
```

```ts no-repl file=../examples/count-v3.most
actor {
  stable var state : Int
};
```

## 互換性のないアップグレード

カウンターの型が再度変更され、今回は [`Int`](../base/Int.md) から [`Nat`](../base/Float.md) に変更された例を見てみましょう：

```ts no-repl file=../examples/count-v4.mo
import Float "mo:base/Float";

persistent actor Counter_v4 {
  var state : Float = 0.0; // implicitly `stable`

  public func increment() : async () {
    state += 0.5;
  };

  public func decrement() : async () {
    state -= 0.5;
  };

  public query func read() : async Float {
    return state;
  };
};
```

このバージョンは、Candid インターフェースおよび安定型宣言のどちらにも互換性がありません。
- `Float </: Int` のため、`state` の新しい型は古い型と互換性がありません。
- `read` の返り値の型変更も無効です。

Motoko は [強化された直交的永続性](orthogonal-persistence/enhanced.md)により、互換性のない状態変更を伴うアップグレードを拒否します。
これにより、安定した状態が常に安全に保持されます。

```
Canister からのエラー ...: Canister called `ic0.trap` with message: RTS error: Memory-incompatible program upgrade.
```

```
Error from Canister ...: Canister called `ic0.trap` with message: RTS error: Memory-incompatible program upgrade.
```

Motoko のチェックに加え、`dfx` はこれらの互換性のない変更に対して警告メッセージを表示します。

:::danger
[古典的な直交的永続性](orthogonal-persistence/classical.md) を使用している Motoko のバージョンでは、`dfx` の警告を無視すると、`v2.wasm` から `v3.wasm` へのアップグレードが予測できず、部分的または完全なデータ損失が発生する可能性があります。
:::

## 明示的な移行

構造を変更するためには、直接型変更が互換性がない場合でも、常に移行経路があります。

この目的のため、ユーザーによる明示的な移行は3つのステップで実行できます：

1. 必要な型の新しい変数を導入し、古い宣言を保持します。
2. アップグレード時に古い変数から新しい変数への状態コピーのロジックを書きます。

   [`Int`](../base/Int.md) から [`Nat`](../base/Float.md) への変更が無効だった以前の試みは、次のようにして希望する変更を実現できます：

```ts no-repl file=../examples/count-v5.mo
import Debug "mo:base/Debug";
import Float "mo:base/Float";

persistent actor Counter_v5 {
  var state : Int = 0; // implicitly `stable`
  var newState : Float = Float.fromInt(state); // implicitly `stable`

  public func increment() : async () {
    newState += 0.5;
  };

  public func decrement() : async () {
    newState -= 0.5;
  };

  public query func read() : async Int {
    Debug.trap("No longer supported: Use `readFloat`");
  };

  public query func readFloat() : async Float {
    return newState;
  };
};
```

   また、Candid インターフェースを保持するために、`readFloat` を追加し、古い `read` はその宣言を保持し、内部でトラップを発生させて非活性化します。

3. すべてのデータが移行されたら、古い宣言を削除します：

```ts no-repl file=../examples/count-v6.mo
import Debug "mo:base/Debug";
import Float "mo:base/Float";

persistent actor Counter_v6 {
  var newState : Float = 0.0; // implicitly `stable`

  public func increment() : async () {
    newState += 0.5;
  };

  public func decrement() : async () {
    newState -= 0.5;
  };

  public query func read() : async Int {
    Debug.trap("No longer supported: Use `readFloat`");
  };

  public query func readFloat() : async Float {
    return newState;
  };
};
```

または、`state` の型を `Any` に変更することもでき、これによりこの変数はもう使用されなくなります。

## アップグレードツール

`dfx` にはアップグレードチェック機能が組み込まれています。この目的のために、Motoko コンパイラ（`moc`）を使用して以下をサポートします：

-   `moc --stable-types …​`: 安定型を `.most` ファイルに出力します。

-   `moc --stable-compatible <pre> <post>`: 2つの `.most` ファイルのアップグレード互換性をチェックします。

Motoko は `.did` と `.most` ファイルを Wasm カスタムセクションとして埋め込み、`dfx` や他のツールで使用されます。

例えば、`cur.wasm` から `nxt.wasm` へアップグレードする場合、`dfx` は Candid インターフェースと安定変数が互換性があることを確認します：

```
didc check nxt.did cur.did  // nxt <: cur
moc --stable-compatible cur.most nxt.most  // cur <<: nxt
```

上記のバージョンを使用すると、`v3` から `v4` へのアップグレードはこのチェックに失敗します：

```
> moc --stable-compatible v3.most v4.most
(unknown location): Compatibility error [M0170], stable variable state of previous type
  var Int
cannot be consumed at new type
  var Float
```

[強化された直交的永続性](orthogonal-persistence/enhanced.md)により、安定変数の互換性エラーはランタイムシステムで常に検出され、失敗した場合、アップグレードは安全にロールバックされます。

:::danger
ただし、[古典的な直交的永続性](orthogonal-persistence/classical.md) では、`v2.wasm` から `v3.wasm` へのアップグレード試行は予測不可能であり、`dfx` の警告を無視すると部分的または完全な

データ損失が発生する可能性があります。
:::

## レコードフィールドの追加

互換性のないアップグレードの一般的な実世界の例は、[フォーラム](https://forum.dfinity.org/t/questions-about-data-structures-and-migrations/822/12?u=claudio/) にあります。

この例では、ユーザーがレコードペイロードにフィールドを追加しようとしていました。

```ts no-repl
persistent actor {
  type Card = {
    title : Text;
  };
  var map : [(Nat32, Card)] = [(0, { title = "TEST"})];
};
```

を*互換性のない* 安定型インターフェースにアップグレードしようとしました：

```ts no-repl
persistent actor {
  type Card = {
    title : Text;
    description : Text;
  };
  var map : [(Nat32, Card)] = [];
};
```

### 問題

このアップグレードを試みると、`dfx` は次の警告を発します：

```
Stable interface compatibility check issued an ERROR for canister ...
Upgrade will either FAIL or LOSE some stable variable data.

(unknown location): Compatibility error [M0170], stable variable map of previous type
  var [(Nat32, Card)]
cannot be consumed at new type
  var [(Nat32, Card__1)]

Do you want to proceed? yes/No
```

これを続行することは推奨されません。なぜなら、古いバージョンの Motoko を使用している場合、[古典的な直交的永続性](orthogonal-persistence/classical.md) によって、状態が失われる可能性があるためです。強化された直交的永続性では、アップグレード時に状態がロールバックされ、古い状態が保持されます。

新しいフィールドを既存の安定変数の型に追加することはサポートされていません。理由は簡単です：アップグレードには新しいフィールドに対して値を生成する必要があるためです。この例では、アップグレードは `map` 内の各 `card` に対して `description` フィールドに値を作成する必要があります。さらに、オプションフィールドの追加を許可することも問題であり、レコードはさまざまな変数から共有されており、異なる静的型が含まれる可能性があり、同じ名前のフィールドや異なる型（および/または異なるセマンティクス）のオプションフィールドを追加する可能性があります。

### 解決方法

この問題を解決するには、[明示的な移行](#explicit-migration) が必要です：

1. 古い変数 `map` を同じ構造の型で保持します。ただし、型エイリアス名（`Card` を `OldCard` に変更すること）は許可されます。
2. 新しい変数 `newMap` を導入し、古い状態を新しいものにコピーし、新しいフィールドを必要に応じて初期化します。
3. その後、この新しいバージョンにアップグレードします。

```ts no-repl
import Array "mo:base/Array";

persistent actor {
  type OldCard = {
    title : Text;
  };
  type NewCard = {
    title : Text;
    description : Text;
  };
  var map : [(Nat32, OldCard)] = [];
  var newMap : [(Nat32, NewCard)] = Array.map<(Nat32, OldCard), (Nat32, NewCard)>(
    map,
    func(key, { title }) { (key, { title; description = "<empty>" }) },
  );
};
```

4. **新しいバージョンに成功裏にアップグレードした後**、古い `map` を削除したバージョンに再度アップグレードできます。

```ts no-repl
persistent actor {
  type Card = {
    title : Text;
    description : Text;
  };
  var newMap : [(Nat32, Card)] = [];
};
```

`dfx` は、`map` が削除されることに対して警告を出します。

この最終的な削減バージョンを適用する前に、古い状態を `newMap` に移行していることを確認してください。

```
Stable interface compatibility check issued a WARNING for canister ...
(unknown location): warning [M0169], stable variable map of previous type
  var [(Nat32, OldCard)]
 will be discarded. This may cause data loss. Are you sure?
```
