---
sidebar_position: 10
---

# ハートビート

ICPのカニスターは、特定の`canister_heartbeat`関数（[heartbeat](https://smartcontracts.org/docs/interface-spec/index.html#heartbeat)を参照）を公開することで、定期的なハートビートメッセージを受け取るように設定できます。

Motokoでは、アクターは引数なしで、`async ()`型の未来を返す`heartbeat`という名前の`system`関数を宣言することにより、ハートビートメッセージを受け取ることができます。

## ハートビートの使用

簡単な例として、`n`回目のハートビートごとに自分自身にメッセージを送る再帰的なアラームがあります：

```ts
import Debug "mo:base/Debug";

persistent actor Alarm {

  let n = 5;
  var count = 0;

  public shared func ring() : async () {
    Debug.print("Ring!");
  };

  system func heartbeat() : async () {
    if (count % n == 0) {
      await ring();
    };
    count += 1;
  }
}
```

`heartbeat`関数は、ICPサブネットのハートビートごとに、`heartbeat`関数への非同期呼び出しをスケジュールすることによって呼ばれます。`async`型の戻り値を持つため、ハートビート関数はさらにメッセージを送信し、結果を待つことができます。ハートビート呼び出しの結果（トラップやエラーが発生した場合も含む）は無視されます。すべてのMotoko非同期関数を呼び出す際に伴う暗黙のコンテキスト切り替えにより、`heartbeat`本体が実行される時間は、サブネットからハートビートが発行された時間より遅れることがあります。

`async`関数として、`Alarm`の`heartbeat`関数は、他の非同期関数や、他のカニスターの共有関数を呼び出すことができます。
