以下が日本語に翻訳された内容です：

---
sidebar_position: 3
---

# 開発者環境

Motokoカニスタースマートコントラクトを開発およびデプロイするには、Motokoコンパイラとベースライブラリを含む開発者環境が必要です。[IC SDK](https://github.com/dfinity/sdk#readme)を使用することをお勧めします。これにはMotokoが含まれており、ICP上でカニスターを作成、ビルド、デプロイするために使用されるコマンドラインツール`dfx`も含まれています。

開発者環境にはいくつかのタイプと形式があり、開発を柔軟でアクセスしやすくしています。

## クラウド環境

[Gitpod](https://www.gitpod.io/)や[GitHub Codespaces](https://github.com/features/codespaces)は、Motokoスマートコントラクトのビルド、テスト、実行を行うために使用できるブラウザベースの開発環境です。

オンラインでMotokoカニスターを開発するためのスタータープロジェクトは以下です：

* [ICP Hello World Motoko](https://github.com/dfinity/icp-hello-world-motoko#readme)
* [Vite + React + Motoko](https://github.com/rvanasa/vite-react-motoko#readme)

Motoko開発のための[Gitpod](/docs/current/developer-docs/developer-tools/ide/gitpod)や[GitHub Codespaces](/docs/current/developer-docs/developer-tools/ide/codespaces)の詳細について学びましょう。

## コンテナ環境

開発者はMotokoやICP関連の開発のためにコンテナ化された環境を設定したい場合があります。コンテナ環境は特にWindowsベースのシステムに便利です。なぜなら、`dfx`はWindowsではネイティブにサポートされていないからです。

Motoko開発のための[開発者コンテナ](/docs/current/developer-docs/developer-tools/ide/dev-containers)や[Dockerコンテナ](/docs/current/developer-docs/developer-tools/ide/dev-containers#using-docker-directly)の詳細について学びましょう。

## Motokoプレイグラウンド

[Motokoプレイグラウンド](https://play.motoko.org/)は、カニスタースマートコントラクトの一時的なデプロイとテストを可能にするブラウザベースの開発者環境です。Motokoプレイグラウンドは、CLI経由で`dfx deploy --playground`コマンドを使用しても利用できます。

Motokoプレイグラウンドにデプロイされたカニスターは、カニスタープールからリソースを借りて使用しており、デプロイ時間は最大20分に制限されています。したがって、プレイグラウンドは長期的な開発には推奨されません。

[Motokoプレイグラウンド](/docs/current/developer-docs/developer-tools/ide/playground)の詳細について学びましょう。

## ローカル開発者環境

Motokoの開発を始める前に、次のことを確認してください：

- [x] インターネット接続があり、ローカルのmacOSまたはLinuxコンピュータでシェルターミナルにアクセスできること。

- [x] コマンドラインインターフェース（CLI）ウィンドウが開いていること。このウィンドウは「ターミナルウィンドウ」とも呼ばれます。

- [x] [IC SDKのインストール](/docs/current/developer-docs/getting-started/install)ページに記載された通り、IC SDKパッケージをダウンロードしてインストールしていること。

- [x] コードエディタがインストールされていること。[VS Code IDE](https://code.visualstudio.com/download)（[Motoko拡張機能](https://marketplace.visualstudio.com/items?itemName=dfinity-foundation.vscode-motoko)付き）が人気の選択肢です。

- [x] [git](https://git-scm.com/downloads)をダウンロードしてインストールしていること。

- [x] 上記のすべてのパッケージとツールが最新のリリースバージョンに更新されていること。

## Motokoのバージョン

以下の表は、各IC SDKのメジャーバージョンで提供されるMotokoのバージョンを示しています。

| IC SDKバージョン | Motokoバージョン |
|------------------|------------------|
| 0.20.0           | 0.11.1           |
| 0.19.0           | 0.11.1           |
| 0.18.0           | 0.11.0           |
| 0.17.0           | 0.10.4           |
| 0.16.0           | 0.10.4           |
| 0.15.0           | 0.9.7            |
| 0.14.0           | 0.8.7            |
| 0.13.0           | 0.7.6            |
| 0.12.0           | 0.7.3            |
| 0.11.0           | 0.6.29           |
| 0.10.0           | 0.6.26           |
| 0.9.0            | 0.6.20           |
| 0.8.0            | 0.6.5            |
| 0.7.0            | 0.6.1            |

IC SDKのバージョンに対応するMotokoのバージョンを知るには、以下のファイルを参照できます：

```
https://github.com/dfinity/sdk/blob/<VERSION>/nix/sources.json#L144
```

`<VERSION>`をIC SDKのリリースバージョン（例：`0.14.2`）に置き換えてください。

## カスタム開発者環境

### カスタムバージョンのコンパイラ指定

Motokoコンパイラのカスタムバージョンを`dfx`で使用するには、パッケージマネージャ`mops`または`vessel`を使用できます。

`mops`の場合、以下のコマンドで異なるバージョンのMotokoコンパイラ（`moc`）をダウンロードします：

```
mops toolchain use moc 0.10.3
```

`vessel`の場合、次の環境変数を設定します：

```
DFX_MOC_PATH="$(vessel bin)/moc" dfx deploy
```

### カスタムバージョンのベースライブラリ指定

Motokoベースライブラリのカスタムバージョンを`dfx`で使用するには、パッケージマネージャ`mops`を使用して以下のコマンドを実行します：

```
mops add base@<VERSION>
```

たとえば、ベースライブラリのバージョン`0.9.0`を使用するには、次のコマンドを実行します：

```
mops add base@0.9.0
```

### カスタムバージョンの`dfx`指定

カスタムバージョンの`dfx`を指定するには、[`dfxvm`ツール](/docs/current/developer-docs/developer-tools/cli-tools/dfxvm/docs/cli-reference/dfxvm/dfxvm-default)を使用します。プロジェクトで使用する`dfx`のデフォルトバージョンを設定するには、次のコマンドを実行します：

```
$ dfxvm default 0.7.2
...
info: installed dfx 0.7.2
info: set default version to dfx 0.7.2
```

### `dfx.json`で`moc`にフラグを渡す

Motokoカニスターの説明で`dfx.json`ファイルに`args`フィールドを追加することで、`moc`にフラグを直接渡すことができます：

以下は`args`を使用した`dfx.json`のカニスター設定例です：

```json
...
  "canisters": {
    "hello": {
      "type": "motoko",
      "main": "src/hello/main.mo",
      "args": "-v --incremental-gc"
    },
  }
...
```
