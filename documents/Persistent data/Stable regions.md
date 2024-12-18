---
sidebar_position: 1
---

# ステーブル領域

`Region`ライブラリは、ICPのステーブルメモリ機能への低レベルアクセスを提供します。

ステーブル領域は、[古典的な直交永続性](../canister-maintenance/orthogonal-persistence/classical.md)で導入され、アップグレード間でより大規模なデータを保持するために使用されます。この目的のために、プログラマーはステーブルメモリに永続データを明示的に格納し、領域を使って異なるインスタンスがステーブルメモリを隔離できるようにしました。

これは[強化された直交永続性](../canister-maintenance/orthogonal-persistence/enhanced.md)によって置き換えられました。それでも、領域は後方互換性のため、また開発者が永続的な線形メモリでデータを明示的に管理したい特定のユースケースのために提供されています。

## `Region`ライブラリ

`base`パッケージの[`Region`](../base/Region.md)ライブラリは、プログラマーが64ビットのステーブルメモリページを順次割り当て、それらのページを使用して、ユーザー定義のバイナリフォーマットでデータを順次読み書きできるようにします。

複数のページを一度に割り当てることができ、各ページは64KiBを含みます。割り当てはICPによって課せられたリソース制限により失敗する場合があります。ページはゼロで初期化されます。

ユーザーは64KiBページの単位で割り当てますが、実装では現在、物理的なステーブルメモリページ128個単位の粗い粒度で割り当てられます。

Motokoランタイムシステムは、`Region`ライブラリによって提供される抽象化とアクターのステーブル変数の間に干渉がないことを保証します。これにより、Motokoプログラムがステーブル変数と`Region`の両方を同じアプリケーション内で安全に利用できるようになります。

さらに、異なる`Region`は異なるステーブルメモリページを使用するため、通常の操作中やアップグレード中に、異なる`Region`が互いのデータ表現に干渉することはありません。

## `Region`の使用

`Region`ライブラリのインターフェースは、現在割り当てられているステーブルメモリページセットを照会し、増やす関数と、Motokoの固定サイズスカラー型に対する`load`および`store`操作のペアで構成されています。

さらに一般的な`loadBlob`および`storeBlob`操作も利用でき、これを使って、任意のサイズの[`Blob`](../base/Blob.md)としてエンコードされたバイナリブロブやその他の型を読み書きできます。

```ts no-repl
module {

  // ICのステーブルメモリの孤立した領域への状態管理用ハンドル。
  // `Region`はステーブル型であり、領域はステーブル変数に保存できます。
  type Region = Prim.Types.Region;

  // 新しい、孤立した`Region`をサイズ0で割り当て。
  new : () -> Region;

  // 領域`r`の現在のサイズ（ページ単位）。
  // 各ページは64KiB（65536バイト）。
  // 初期値は`0`。
  size : (r : Region) -> (pages : Nat64);

  // 現在の領域`r`の`size`を`pagecount`ページ分増やす。
  // 各ページは64KiB（65536バイト）。
  // 増加に成功した場合は、以前の`size`を返す。
  // 物理的なステーブルメモリページの残りが不足している場合、`0xFFFF_FFFF_FFFF_FFFF`を返す。
  // 領域のサイズを縮小する方法はありません。
  grow : (r : Region, new_pages : Nat64) -> (oldpages : Nat64);

  // 領域からバイトを読み込む（"load"）。
  loadNat8 : (r : Region, offset : Nat64) -> Nat8;

  // 領域にバイトを書き込む（"store"）。
  storeNat8 : (r : Region, offset : Nat64, value: Nat8) -> ();

  // ...および、Nat16、Nat32、Nat64、Int8、Int16、Int32、Int64に対して同様の操作。

  loadFloat : (r : Region, offset : Nat64) -> Float;
  storeFloat : (r : Region, offset : Nat64, value : Float) -> ();

  // 領域`r`の`offset`から`size`バイトを[`Blob`](../base/Blob.md)として読み込む。
  // 範囲外アクセスではトラップ。
  loadBlob : (r : Region, offset : Nat64, size : Nat) -> Blob;

  // [`Blob`](../base/Blob.md)のすべてのバイトを`offset`から領域`r`に書き込む。
  // 範囲外アクセスではトラップ。
  storeBlob : (r : Region, offset : Nat64, value : Blob) -> ()

}
```

:::danger
ステーブル領域は低レベルの線形メモリを公開しており、プログラマーはこのデータを適切に操作し解釈する責任があります。
ステーブル領域でデータを管理する際は、非常にエラーが発生しやすくなります。
ただし、Motokoのネイティブ値ヒープオブジェクトの安全性は常に保証されており、ステーブル領域の内容に関係なく保護されます。
:::

:::note
ステーブル領域へのアクセスのコストは、Motokoのネイティブメモリ（通常のMotoko値およびオブジェクト）を使用するよりもかなり高いです。
:::

## 例

`Region`ライブラリの使用を示すために、以下はスケーラブルで永続的なログにテキストメッセージを記録するシンプルなロギングアクターの実装例です。

この例は、ステーブル変数とステーブルメモリを同時に使用しています。1つのステーブル変数`state`を使用して2つの領域とそのサイズ（バイト単位）を追跡しますが、ログの内容は直接ステーブルメモリに保存されます。

```ts no-repl file=../examples/StableMultiLog.mo
import Nat64 "mo:base/Nat64";
import Region "mo:base/Region";

persistent actor StableLog {

  // Index of saved log entry.
  public type Index = Nat64;

  // Internal representation uses two regions, working together.
  var state = { // implicitly `stable`
    bytes = Region.new();
    var bytes_count : Nat64 = 0;
    elems = Region.new ();
    var elems_count : Nat64 = 0;
  };

  // Grow a region to hold a certain number of total bytes.
  func regionEnsureSizeBytes(r : Region, new_byte_count : Nat64) {
    let pages = Region.size(r);
    if (new_byte_count > pages << 16) {
      let new_pages = ((new_byte_count + ((1 << 16) - 1)) / (1 << 16)) - pages;
      assert Region.grow(r, new_pages) == pages
    }
  };

  // Element = Position and size of a saved a Blob.
  type Elem = {
    pos : Nat64;
    size : Nat64;
  };

  transient let elem_size = 16 : Nat64; /* two Nat64s, for pos and size. */

  // Count of elements (Blobs) that have been logged.
  public func size() : async Nat64 {
      state.elems_count
  };

  // Constant-time random access to previously-logged Blob.
  public func get(index : Index) : async Blob {
    assert index < state.elems_count;
    let pos = Region.loadNat64(state.elems, index * elem_size);
    let size = Region.loadNat64(state.elems, index * elem_size + 8);
    let elem = { pos ; size };
    Region.loadBlob(state.bytes, elem.pos, Nat64.toNat(elem.size))
  };

  // Add Blob to the log, and return the index of it.
  public func add(blob : Blob) : async Index {
    let elem_i = state.elems_count;
    state.elems_count += 1;

    let elem_pos = state.bytes_count;
    state.bytes_count += Nat64.fromNat(blob.size());

    regionEnsureSizeBytes(state.bytes, state.bytes_count);
    Region.storeBlob(state.bytes, elem_pos, blob);

    regionEnsureSizeBytes(state.elems, state.elems_count * elem_size);
    Region.storeNat64(state.elems, elem_i * elem_size + 0, elem_pos);
    Region.storeNat64(state.elems, elem_i * elem_size + 8, Nat64.fromNat(blob.size()));
    elem_i
  }

};
```

共有された`add(blob)`関数は、指定されたブロブを格納するために十分なステーブルメモリを割り当て、そのブロブの内容、サイズ、位置を事前に割り当てられた領域に書き込みます。1つの領域はさまざまなサイズのブロブを格納するために専用され、もう1つの領域はその固定サイズのメタデータを格納するために専用されます。

共有された`get(index)`クエリは、関連のないメモリを走査することなく、ログの任意の場所から読み取ります。

`StableLog`は、その潜在的に大きなログデータを直接ステーブルメモリに割り当て、実際のステーブル変数のためには少量で固定されたストレージを使用します。`StableLog`のアップグレードは、ログのサイズに関わらず多くのサイクルを消費することはありません。

## ステーブル領域用のMopsパッケージ

- [`memory-region`](https://mops.one/memory-region): `Region`型を抽象化し、解放されたメモリを再利用できるようにサポートするライブラリ。

- [`stable-enum`](https://mops.one/stable-enum): ステーブル領域で実装された列挙型。

- [`stable-buffer`](https://mops.one/stable-buffer): ステーブル領域で実装されたバッファ。
