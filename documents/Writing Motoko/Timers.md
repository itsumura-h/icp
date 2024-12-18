---
sidebar_position: 26
---

# タイマー

ICP 上では、カニスターは指定された時間または定期的な間隔後にコードの一部を実行する定期的なタイマーを設定できます。Motoko の時間は [`Timer.mo`](../base/Timer.md) モジュールを使用して実装され、`TimerId` を返します。`TimerId` は各タイマーインスタンスに対して一意です。1つのカニスターは複数のタイマーを持つことができます。

## 例

簡単な例として、新年のメッセージをログに記録する定期的なリマインダーがあります：

```ts no-repl file=../examples/Reminder.mo
import { print } = "mo:base/Debug";
import { abs } = "mo:base/Int";
import { now } = "mo:base/Time";
import { setTimer; recurringTimer } = "mo:base/Timer";

persistent actor Reminder {

  transient let solarYearSeconds = 356_925_216;

  private func remind() : async () {
    print("Happy New Year!");
  };

  ignore setTimer<system>(#seconds (solarYearSeconds - abs(now() / 1_000_000_000) % solarYearSeconds),
    func () : async () {
      ignore recurringTimer<system>(#seconds solarYearSeconds, remind);
      await remind();
  });
}
```

基盤となるメカニズムは、[カニスターのグローバルタイマー](https://internetcomputer.org/docs/current/references/ic-interface-spec#timer)で、デフォルトでは Motoko ランタイムが管理する優先度キューから適切なコールバックとともに発行されます。

タイマーのメカニズムは、`moc` に `-no-timer` フラグを渡すことで完全に無効にすることができます。

## 低レベルアクセス

カニスターのグローバルタイマーへの低レベルアクセスを希望する場合、アクターは `timer` という名前の `system` 関数を宣言することでタイマーの期限切れメッセージを受け取ることができます。この関数はグローバルタイマーをリセットするために使用される引数を1つ受け取り、`async ()` 型のフューチャーを返します。

`timer` システムメソッドが宣言されている場合、[`Timer.mo`](../base/Timer.md) ベースライブラリモジュールは正しく動作せず、使用しない方が良いです。

以下の例では、グローバルタイマーの期限切れコールバックがカニスターが起動した直後（つまりインストール後）およびその後毎20秒ごとに呼び出されます：

```ts no-repl
system func timer(setGlobalTimer : Nat64 -> ()) : async () {
  let next = Nat64.fromIntWrap(Time.now()) + 20_000_000_000;
  setGlobalTimer(next); // ナノ秒単位の絶対時間
  print("Tick!");
}
```

<img src="https://github.com/user-attachments/assets/844ca364-4d71-42b3-aaec-4a6c3509ee2e" alt="Logo" width="150" height="150" />
