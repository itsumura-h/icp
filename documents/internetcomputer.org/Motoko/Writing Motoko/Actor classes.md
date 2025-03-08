---
sidebar_position: 3
---

# アクタークラス

アクタークラスは、アクターのネットワークをプログラム的に作成することを可能にします。アクタークラスは別のソースファイルで定義する必要があります。アクタークラスを定義してインポートする方法を示すために、以下の例では、[`Nat`](../base/Nat.md)型のキーを[`Text`](../base/Text.md)型の値にマッピングする分散型マップを実装しています。この例では、キーと値を操作するためのシンプルな挿入および検索関数`put(k, v)`と`get(k)`を提供しています。

## アクタークラスの定義

この例でデータを分散させるため、キーのセットは`n`個のバケットに分割されます。今回は、`n = 8`に固定します。キー`k`のバケット`i`は、`k % n`（すなわち、`i = k % n`）によって決定されます。キー`k`の`i`番目のバケット（`i`は`[0..n)`）には、そのバケットに割り当てられたテキスト値を保存する専用のアクターが割り当てられます。

バケット`i`を担当するアクターは、サンプル`Buckets.mo`ファイルで定義されたアクタークラス`Bucket(i)`のインスタンスとして取得されます。次のように定義されています：

`Buckets.mo`:

``` ts
import Nat "mo:base/Nat";
import Map "mo:base/OrderedMap";

persistent actor class Bucket(n : Nat, i : Nat) {

  type Key = Nat;
  type Value = Text;

  transient let keyMap = Map.Make<Key>(Nat.compare);

  var map : Map.Map<Key, Value> = keyMap.empty();

  public func get(k : Key) : async ?Value {
    assert((k % n) == i);
    keyMap.get(map, k);
  };

  public func put(k : Key, v : Value) : async () {
    assert((k % n) == i);
    map := keyMap.put(map, k, v);
  };

};
```

バケットは、ミュータブルな`map`変数内の現在のキーから値へのマッピングを保存します。`map`は最初は空の命令的なRedBlackツリーです。

`get(k)`では、バケットアクターは単に`k`に保存された値を返し、`map.get(k)`を返します。

`put(k, v)`では、バケットアクターは現在の`map`を更新し、`map.put(k, v)`を呼び出して`k`を`?v`にマッピングします。

両方の関数は、`n`と`i`というクラスのパラメータを使用して、`k`がそのバケットに適切であることを確認します（`((k % n) == i)`をアサートします）。

マップのクライアントは、その後、次のように実装された調整役の`Map`アクターと通信できます：

``` ts
import Array "mo:base/Array";
import Buckets "Buckets";

persistent actor Map {

  let n = 8; // number of buckets

  type Key = Nat;
  type Value = Text;

  type Bucket = Buckets.Bucket;

  let buckets : [var ?Bucket] = Array.init(n, null);

  public func get(k : Key) : async ?Value {
    switch (buckets[k % n]) {
      case null null;
      case (?bucket) await bucket.get(k);
    };
  };

  public func put(k : Key, v : Value) : async () {
    let i = k % n;
    let bucket = switch (buckets[i]) {
      case null {
        let b = await Buckets.Bucket(n, i); // dynamically install a new Bucket
        buckets[i] := ?b;
        b;
      };
      case (?bucket) bucket;
    };
    await bucket.put(k, v);
  };

};
```

この例が示すように、`Map`コードは`Bucket`アクタークラスを`Buckets`モジュールとしてインポートしています。

アクターは、`n`個の割り当てられたバケットの配列を維持し、すべてのエントリは最初は`null`です。エントリは、必要に応じて`Bucket`アクターで埋められます。

`get(k, v)`では、`Map`アクターは次の操作を行います：

- キー`k`を`n`で割った余りを使用して、そのキーを担当するバケットのインデックス`i`を決定します。

- `i`番目のバケットが存在しない場合は`null`を返し、

- 存在する場合は、そのバケットに委任して`bucket.get(k, v)`を呼び出します。

`put(k, v)`では、`Map`アクターは次の操作を行います：

- キー`k`を`n`で割った余りを使用して、そのキーを担当するバケットのインデックス`i`を決定します。

- バケットが存在しない場合、非同期呼び出しで`Buckets.Bucket(i)`コンストラクタを使用してバケット`i`をインストールし、結果を待機した後、`buckets`配列に記録します。

- 挿入をそのバケットに委任し、`bucket.put(k, v)`を呼び出します。

この例では、バケットの数を`8`に設定していますが、`Map`アクターをアクタークラスとして一般化し、パラメータ`(n : Nat)`を追加して、`let n = 8;`の宣言を省略することができます。

例えば：

``` motoko no-repl
actor class Map(n : Nat) {

  type Key = Nat
  ...
}
```

`Map`アクタークラスのクライアントは、ネットワーク内のバケットの最大数を、インスタンス化時に引数を渡すことで自由に決定できます。

:::note

ICPでは、クラスコンストラクタへの呼び出しには、プリンシパルの作成のためにサイクルを提供する必要があります。サイクルを呼び出しに追加する方法については、[ExperimentalCycles](../base/ExperimentalCycles.md)のドキュメントを参照してください。

:::

## アクタークラスインスタンスの構成と管理

ICPでは、インポートされたアクタークラスの主コンストラクタは常に新しいプリンシパルを作成し、そのプリンシパルのコードとしてクラスの新しいインスタンスをインストールします。

アクタークラスのインストールをさらに制御するために、Motokoはインポートされた各アクタークラスに追加のセカンダリコンストラクタを提供します。このコンストラクタは、インストールモードを指定する追加の最初の引数を取ります。このコンストラクタは、`system`機能を強調する特別な構文でのみ利用可能です。

この構文を使用することで、初期のカニスター設定（例えば、コントローラの配列）を指定したり、カニスターを手動でインストール、アップグレード、再インストールしたりすることができ、インターネットコンピュータの低レベルの機能すべてを公開できます。

詳細については、[アクタークラスの管理](../reference/language-manual#actor-class-management)を参照してください。
