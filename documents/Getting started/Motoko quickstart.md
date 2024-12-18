---
sidebar_position: 4
---

# Motoko クイックスタート

このクイックスタートガイドでは、シンプルな「Hello, world!」Motokoスマートコントラクトをデプロイする方法を紹介します。

## 必要条件

始める前に、[開発者環境ガイド](./dev-env)の手順に従って、開発者環境をセットアップしていることを確認してください。

## 新しいプロジェクトの作成

ローカルコンピュータでターミナルウィンドウを開いていない場合は、開きます。

新しいプロジェクトを作成し、そのディレクトリに移動します。

`dfx new [project_name]`コマンドを使って、新しいプロジェクトを作成します：

```
dfx new hello_world
```

バックエンドカニスターで使用する言語を選択するように求められます：

```
? Select a backend language: ›
❯ Motoko
Rust
TypeScript (Azle)
Python (Kybra)
```

次に、フロントエンドカニスターのためのフレームワークを選択します。この例では、次のように選択します：

```
? Select a frontend framework: ›
SvelteKit
React
Vue
Vanilla JS
No JS template
❯ No frontend canister
```

最後に、プロジェクトに追加する追加機能を選択できます：

```
? Add extra features (space to select, enter to confirm) ›
⬚ Internet Identity
⬚ Bitcoin (Regtest)
⬚ Frontend tests
```

## スマートコントラクトコード

このHello Worldアクターには、`greet`という単一の関数があります。この関数は状態を変更しないため、`query`としてマークされています。関数は`Text`型の名前を入力として受け取り、`Text`型の挨拶を返します。

```motoko title="src/hello_backend/main.mo"

actor {
  public query func greet(name : Text) : async Text {
    return "Hello, " # name # "!";
  };
};
```

## デプロイメント環境の開始

ローカル開発のためにインターネットコンピュータを開始するか、ネットワークデプロイメントのためにインターネットコンピュータへの接続を確認します：
- [ローカルデプロイメント](/docs/current/developer-docs/getting-started/deploy-and-manage)。
- [メインネットデプロイメント](/docs/current/developer-docs/getting-started/deploy-and-manage)。

## ローカルまたはメインネットへの登録、ビルド、デプロイ

ローカルにデプロイするには、次のコマンドを使用します：

```
dfx deploy
```

メインネットにデプロイするには、`--network ic`を使用します：

```
dfx deploy --network <network>
```

## ブラウザでサービスやアプリケーションを表示する

`dfx deploy`コマンドの出力にあるURLを使って、ブラウザでサービスを表示します：

```
...
Committing batch.
Committing batch with 18 operations.
Deployed canisters.
URLs:
Frontend canister via browser
        access_hello_frontend: http://127.0.0.1:4943/?canisterId=cuj6u-c4aaa-aaaaa-qaajq-cai
Backend canister via Candid interface:
        access_hello_backend: http://127.0.0.1:4943/?canisterId=cbopz-duaaa-aaaaa-qaaka-cai&id=ctiya-peaaa-aaaaa-qaaja-cai
```
