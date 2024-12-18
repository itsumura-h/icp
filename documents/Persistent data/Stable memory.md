---
sidebar_position: 2
---

# ステーブルメモリ

[`Region`ライブラリ](stable-regions.md)は、ICP上のステーブルメモリとインタラクションするために使用できます。

このライブラリは、インターネットコンピュータのステーブルメモリに対する低レベルのアクセスを提供します。

:::danger
`ExperimentalStableMemory`ライブラリは廃止されました。

新しいアプリケーションは`Region`ライブラリを使用するべきです。このライブラリは、ステーブルメモリを使用する異なるライブラリ間で追加の分離を提供します。
:::

## ステーブルメモリ用のMopsパッケージ

- [`memory-buffer`](https://mops.one/memory-buffer): 永続的なバッファの実装。

- [`memory-hashtable`](https://mops.one/memory-hashtable): キーごとに1つのブロブ値を格納、更新、削除、取得するためのライブラリ。

- [`StableTrie`](https://mops.one/stable-trie): メインデータがステーブルメモリに永続的に格納されるキー・バリュー・マップデータ構造。

## サンプル

- [motoko-bucket](https://github.com/PrimLabs/Bucket): ステーブルメモリを使用するキー・バリュー・データベースライブラリ。

- [motoko-cdn](https://github.com/gabrielnic/motoko-cdn): 自動スケーリングストレージソリューション。

- [motoko-dht](https://github.com/enzoh/motoko-dht): 分散ハッシュテーブルサンプル。

- [motoko-document-db](https://github.com/DepartureLabsIC/motoko-document-db): ドキュメントデータベースサンプル。

<img src="https://github.com/user-attachments/assets/844ca364-4d71-42b3-aaec-4a6c3509ee2e" alt="Logo" width="150" height="150" />
