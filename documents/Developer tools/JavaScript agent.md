---
キーワード: [中級, エージェント, チュートリアル, JavaScript]
---

# JavaScriptエージェント

エージェントはICPとやり取りするために使用されるAPIクライアントです。[ICP JavaScriptエージェント](https://www.npmjs.com/package/@dfinity/agent)は、ICPの公開APIエンドポイントやICPにデプロイされたカニスターとやり取りするために使用されます。ICP JavaScriptエージェントは、`call`、`query`、`readState`メソッドやその他のユーティリティをエージェントに提供します。

エージェントを介して行われた呼び出しは、アクターを通じて構造化され、[Candidインターフェース](/docs/current/developer-docs/smart-contracts/candid/candid-concepts)から生成できるカニスターのインターフェースで設定されることを意図しています。生の呼び出しもサポートされていますが、ベストプラクティスに従って推奨はされません。

## インストール

### 前提条件
[ICP JavaScriptエージェント](https://www.npmjs.com/package/@dfinity/agent)を始めるには、開発環境に以下を含めることをお勧めします：

- [x] カニスターの作成と管理のためのIC SDK。
- [x] Node.js (12、14、または16)。
- [x] 実験したいカニスター。
  - 推奨事項：
    - `dfx new`によるデフォルトプロジェクト。
    - [dfinity/examples](https://github.com/dfinity/examples)のサンプル。

[ICP JavaScriptエージェント](https://www.npmjs.com/package/@dfinity/agent)をインストールするには、以下のコマンドを実行してください：

```sh
npm i --save @dfinity/agent
```

## 認証

[ICP JavaScriptエージェント](https://www.npmjs.com/package/@dfinity/agent)は、[インターネットアイデンティティサービス](/docs/current/developer-docs/identity/internet-identity/overview)を使用する`auth-client`を介した認証をサポートしています。

まず、`auth-client`パッケージをインストールします：

```sh
npm i --save @dfinity/auth-client
```

認証クライアントを作成し、`identity.ic0.app`ウィンドウを開き、`indexedDb`に委任を保存し、アイデンティティを提供します：

```ts
const authClient = await AuthClient.create();
authClient.login({
  // 7日間（ナノ秒単位）
  maxTimeToLive: BigInt(7 * 24 * 60 * 60 * 1000 * 1000 * 1000),
  onSuccess: async () => {
    handleAuthenticated(authClient);
  },
});
```

その後、そのアイデンティティを使用して、`@dfinity/agent`アクターを使用して認証された呼び出しを行います：

```ts
const identity = await authClient.getIdentity();
const actor = Actor.createActor(idlFactory, {
  agent: new HttpAgent({
    identity,
  }),
  canisterId,
});
```

### ストレージとキー管理

デフォルトでは、[ICP JavaScriptエージェント](https://www.npmjs.com/package/@dfinity/agent)は、デフォルトのIndexedDbストレージインターフェースとECDSAキーを使用します。

`AuthClientStorage`インターフェースを実装する任意のストレージ構造を使用できます。

```ts
export type StoredKey = string | CryptoKeyPair;
export interface AuthClientStorage {
  get(key: string): Promise<StoredKey | null>;

  set(key: string, value: StoredKey): Promise<void>;

  remove(key: string): Promise<void>;
}
```

:::caution

カスタムストレージ実装が文字列データ型のみをサポートする場合は、`keyType`オプションを使用して、デフォルトのECDSAキーの代わりに`Ed25519`キーを使用することをお勧めします：

```ts
const authClient = await AuthClient.create({
  storage: new LocalStorage(),
  keyType: 'Ed25519',
});
```
:::

### セッション管理

AuthClientがサポートするセキュアなセッション管理には2つのオプションがあります：

1. インターネットアイデンティティの委任に組み込まれている`maxTimeToLive`オプションは、`DelegationIdentity`が有効である期間をナノ秒単位で決定します。

2. Idle Managerは、キーボード、マウス、タッチスクリーンの活動を監視します。ブラウザが一定時間操作されないと、Idle Managerは自動的にログアウトします。

    - デフォルトでは、この期間は10分です。10分後、`DelegationIdentity`は`localStorage`から削除され、`window.location.reload()`が呼び出されます。

    - 代わりに、`onIdle`オプションを渡すことで、デフォルトの`window.location.reload()`動作を置き換えることができ、また`idleManager.registerCallback()`を使用して、デフォルトのコールバックも置き換えることができます。

IdleManagerの[オプションの全セット](https://agent-js.icp.xyz/auth-client/index.html)をご覧ください。

## アクターの初期化

エージェントは、最も一般的に`Actor.createActor`コンストラクタを使用してアクターを作成するために使用されます：

```ts
Actor.createActor(interfaceFactory: InterfaceFactory, configuration: ActorConfig): ActorSubclass<T>
```

`interfaceFactory`関数は、アクターがカニスターへの呼び出しを構造化するために使用するランタイムインターフェースを返します。この関数は、プロジェクトで`dfx generate`コマンドを実行するか、`didc`ツールを使用してインターフェースを生成することで作成されます。あるいは、この関数は手動で記述することもできますが、お勧めしません。

[ICP JavaScriptエージェント](https://www.npmjs.com/package/@dfinity/agent)のコンテキストでアクターは以下の目的で使用されます：

- 更新をポーリングする。

- エージェントのリクエストのCandidエンコードされた本体を構築する。

- 応答を解析する。

- カニスターのインターフェースの型安全性を提供する。

HttpAgentに対する呼び出しを単独で行うのは、ほとんどのアプリケーションには不要な高度な使用例です。

アクターを設定するには、カニスターのCandid宣言と`canisterId alias`から`createActor`ユーティリティをインポートできます。デフォルトでは、`process.env<canister-id>_CANISTER_ID`にポイントします。

カニスターID環境変数のロジックを、以下のようにアプリケーションに渡す方法は多数あります：

- `package.json`のスクリプトの最初に編集する（`NFT_CANISTER_ID=... node....`）。

- [dotenv](https://www.npmjs.com/package/dotenv)をインストールし、隠し`.env`ファイルから読み込むように設定する。

以下の例では、ローカル開発を使用し、`.dfx/local/canister_ids.json`ファイルからカニスターIDを読み込むことができます：

```ts
// src/node/index.js
import fetch from "isomorphic-fetch";
import { HttpAgent } from "@dfinity/agent";
import { createRequire } from "node:module";
import { canisterId, createActor } from "../declarations/agent_js_example/index.js";
import { identity } from "./identity.js";

// JSONファイルのインポートにはrequire構文が必要
const require = createRequire(import.meta.url);
const localCanisterIds = require("../../.dfx/local/canister_ids.json");

// `process.env`が使用可能な場合、それを使用します。使用できない場合、ローカルを使用します。
const effectiveCanisterId =
  canisterId?.toString() ?? localCanisterIds.agent_js_example.local;

const agent = new HttpAgent({
  identity: await identity,
  host: "http://127.0.0.1:4943",
  fetch,
});

const actor = createActor(effectiveCanisterId, {
  agent,
});
```

### HTTPヘッダー

アクターは、`Actor.createActor`コンストラクタを使用して、境界ノードのHTTPヘッダーを含むように初期化できます：

```ts
Actor.createActorWithHttpDetails(interfaceFactory: InterfaceFactory, configuration: ActorConfig): ActorSubclass<ActorMethodMappedWithHttpDetails<T>>
```

### アクターのエージェントを調査する

アクターのエージェントを取得するには、`Actor.agentOf`メソッドを使用します：

```ts
const defaultAgent = Actor.agentOf(defaultActor);
```

このメソッドを使用して、アクターのエージェントで使用するアイデンティティを置き換えたり無効にしたりできます。例えば、以下のメソッドを使用して、アクターのエージェントの現在のアイデンティティを新たに認証されたインターネットアイデンティティのアイデンティティに置き換えることができます：

```ts
defaultAgent.replaceIdentity(await authClient.getIdentity());
```

## 呼び出しを行う

[ICP JavaScriptエージェント](https://www.npmjs.com/package/@dfinity/agent)は、ICPへの呼び出しを行うための以下のメソッドをサポートしています：

- `call`: [更新呼び出し](/docs/current/developer-docs/smart-contracts/call/overview/#update-calls)を行うために使用します。

- `query`: [クエリ呼び出し](/docs/current/developer-docs/smart-contracts/call/overview/#query-calls)を行うために使用します。

- `readState`: ICPレプリカからの状態情報を読み取るために使用します。

:::info
エージェントを使用して生の呼び出しを行うことはできますが、エージェントが生成する呼び出しを使用することが推奨されます。
:::

### 更新呼び出し

ICPでの更新呼び出しは、カニスターの状態を変更します。[ICP JavaScriptエージェント](https://www.npmjs.com/package/@dfinity/agent)で更新呼び出しを行うには、`call`メソッドを使用します：

```ts
call(canisterId: string | Principal, fields: CallOptions): Promise<SubmitResponse>
```

このメソッドは[packages/agent/src/agent/api.ts:178](https://github.com/dfinity/agent-js/blob/21e8d2b/packages/agent/src/agent/api.ts#L178)に定義されています。

このメソッドのパラメーターは以下の通りです：

- `canisterId`: カニスターの主キーID（`string`形式）。

- `fields`: 呼び出しのオプション。オプションの詳細は[CallOptions](https://agent-js.icp.xyz/agent/interfaces/CallOptions.html)で確認できます。

`call`メソッドは`Promise<[SubmitResponse](https://agent-js.icp.xyz/agent/interfaces/SubmitResponse.html)>`を返します。

### クエリ呼び出し

ICPでのクエリ呼び出しはカニスターの状態を変更せず、情報を返すだけです。[ICP JavaScriptエージェント](https://www.npmjs.com/package/@dfinity/agent)でクエリ呼び出しを行うには、`query`メソッドを使用します：

```ts
query(canisterId: string | Principal, options: QueryFields, identity?: Identity | Promise<Identity>): Promise<ApiQueryResponse>
```

このメソッドは[packages/agent/src/agent/api.ts:200](https://github.com/dfinity/agent-js/blob/21e8d2b/packages/agent/src/agent/api.ts#L200)に定義されています。

このメソッドのパラメーターは以下の通りです：

- `canisterId`: カニスターの主キーID（`string`形式）。管理カニスターへのクエリ送信はサポートされていません。

- `options`: クエリを作成して送信するためのオプション。オプションの詳細は[QueryFields](https://agent-js.icp.xyz/agent/interfaces/QueryFields.html)で確認できます。

- `identity`: オプション；クエリ送信時に使用する送信者の主キー。

`query`メソッドは`Promise<ApiQueryResponse>`を返します。

### 状態情報の読み取り

ICPレプリカから状態情報を読み取るには、`readState`メソッドを使用します。このメソッドは、戻り値のリストと共にクエリ呼び出しを行い、証明書を受け取ります。通信エラーがある場合、呼び出しは拒否され、証明書には要求された情報よりも少ない情報が含まれている可能性があります。

```ts
readState(effectiveCanisterId: string | Principal, options: ReadStateOptions, identity?: Identity, request?: any): Promise<ReadStateResponse>
```

このメソッドは[packages/agent/src/agent/api.ts:170](https://github.com/dfinity/agent-js/blob/21e8d2b/packages/agent/src/agent/api.ts#L170)に定義されています。

このメソッドのパラメーターは以下の通りです：

- `effectiveCanisterId`: 呼び出しに関連するカニスターの主キーID（`string`形式）。

- `options`: 呼び出しのオプション。オプションの詳細は[ReadStateOptions](https://agent-js.icp.xyz/agent/interfaces/ReadStateOptions.html)で確認できます。

- `identity`: オプション；クエリ送信時に使用する送信者の主キー。指定しない場合、インスタンスのアイデンティティが使用されます。

- `request`: オプション；すでに作成されたリクエスト。

このメソッドは`Promise<ReadStateResponse>`を返します。

## ブラウザ

ブラウザで実行されるアプリを開発する場合、以下のように`fetch`APIを使用できます。ほとんどのアプリでは、`https://icp0.io`またはローカルレプリカと通信する必要があるかどうかをURLに基づいて判定できます。

### `fetch`の使用

[ICP JavaScriptエージェント](https://www.npmjs.com/package/@dfinity/agent)は、ウェブブラウザの`fetch`APIを使用してICPに呼び出しを行います。ブラウザでエージェントが使用されない場合、`fetch`の実装をエージェントのコンストラクタに渡すことができます。
