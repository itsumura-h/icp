---
sidebar_position: 3
---

# 古典的な直交永続性

古典的な直交永続性は、Motokoの直交永続性の旧実装です。現在もデフォルトオプションとして使用されていますが、強化された直交永続性はベータテスト段階にあります。

アップグレード時、古典的な直交永続性のメカニズムは、すべての安定データを安定メモリにシリアライズし、その後メインメモリにデシリアライズします。これにはいくつかの欠点があります：

* 最大で2 GiBのヒープデータがアップグレード間で永続化されます。これは実装制限によるものです。実際には、サポートされる安定データ量はこれよりもかなり少ない場合があります。
* 共有された不変ヒープオブジェクトが重複することがあり、アップグレード時に状態の爆発を引き起こす可能性があります。
* 深くネストされた構造がコールスタックオーバーフローを引き起こす可能性があります。
* シリアライズとデシリアライズは高コストで、ICの命令制限に達することがあります。
* ランタイムシステムには組み込みの安定互換性チェックがありません。ユーザーが`dfx`のアップグレード警告を無視すると、データが失われるか、アップグレードが失敗する可能性があります。

:::danger
これらの問題は、アップグレードできなくなったカニスターを引き起こす可能性があります。
そのため、アプリケーションのアップグレードで処理できるデータ量を徹底的にテストし、そのカニスターが保持するデータ量を慎重に制限することが絶対に必要です。
さらに、アップグレードが失敗してもデータを回復できるバックアップ手段（例：コントローラ権限によるデータクエリ呼び出し）を準備しておくと良いでしょう。
:::

これらの問題は[強化された直交永続性](enhanced.md)によって解決されます。
