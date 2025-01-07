https://internetcomputer.org/docs/current/developer-docs/identity/internet-identity/integrate-internet-identity

https://github.com/dfinity/portal/blob/master/docs/developer-docs/identity/internet-identity/integrate-internet-identity.mdx

---
キーワード: [中級, チュートリアル, ユーザーサインイン, ユーザーログイン, インターネットアイデンティティ]
---

# IIとの統合

<MarkdownChipRow labels={["中級", "チュートリアル"]} />

このガイドでは、インターネットアイデンティティ（II）をアプリケーションに統合する方法の例を示します。具体的には、シンプルな「Who am I?」バックエンドカニスターと、バックエンドの`whoami`メソッドを呼び出すユーザーのインターネットアイデンティティプリンシパルを返すフロントエンドUIを使用します。

このプロジェクトでは、インターネットアイデンティティカニスターの**プル可能**バージョンを使用しています。プル可能カニスターは、静的なカニスターIDで公共サービスを提供するカニスターです。プル可能カニスターについて詳細を知るには、[ドキュメント](https://docs.dfinity.org/docs/current/developer-docs/smart-contracts/maintain/import)を参照してください。

<Tabs>
<TabItem value="prereq" label="前提条件" default>

<input type="checkbox"/> <a href="/docs/current/developer-docs/getting-started/install">IC SDKをインストールする。</a>

</TabItem>
</Tabs>

## II認証を使用したシンプルなアプリの作成

### ステップ1: プロジェクトの作成または開く

まず、必要に応じて[ローカルレプリカを起動](/docs/current/developer-docs/developer-tools/cli-tools/cli-reference/dfx-start)し、[プロジェクトを作成](/docs/current/developer-docs/developer-tools/cli-tools/cli-reference/dfx-new)または開いてください。

### ステップ2: バックエンドコードの編集

このプロジェクトでは、シンプルな「Who am I?」関数をバックエンドカニスターに使用します。`src/ii_integration_backend/main.mo`ファイルを開き、既存の内容を以下のコードに置き換えます：

```ts title="src/ii_integration_backend/main.mo"
actor {
    public shared (msg) func whoami() : async Principal {
        msg.caller
    };
};
```

このアクターには、呼び出し元のプリンシパルを返す単一のメソッドがあります。これは、アプリケーションのフロントエンドから認証されたインターネットアイデンティティまたは匿名アイデンティティを使用してリクエストを行うと表示されます。

### ステップ3: @dfinity/auth-clientパッケージのインストール

```sh
npm install @dfinity/auth-client
```

### ステップ4: フロントエンドカニスターの`index.js`ファイルの編集

以下のコードを`src/ii_integration_frontend/src/index.js`ファイルに挿入します：

```javascript title="src/ii_integration_frontend/src/index.js"
/* インターネットアイデンティティでユーザーを認証し、その後
 * whoamiカニスターを呼び出してユーザーのプリンシパルを確認するシンプルなWebアプリ。
 */

import { Actor, HttpAgent } from "@dfinity/agent";
import { AuthClient } from "@dfinity/auth-client";

const webapp_id = process.env.WHOAMI_CANISTER_ID;

// whoamiカニスターのインターフェース
const webapp_idl = ({ IDL }) => {
  return IDL.Service({ whoami: IDL.Func([], [IDL.Principal], ["query"]) });
};
export const init = ({ IDL }) => {
  return [];
};

// IIのURLを正しいカニスターにポイントするように自動入力します。
document.body.onload = () => {
  let iiUrl;
  if (process.env.DFX_NETWORK === "local") {
    iiUrl = `http://localhost:4943/?canisterId=${process.env.II_CANISTER_ID}`;
  } else if (process.env.DFX_NETWORK === "ic") {
    iiUrl = `https://${process.env.II_CANISTER_ID}.ic0.app`;
  } else {
    iiUrl = `https://${process.env.II_CANISTER_ID}.dfinity.network`;
  }
  document.getElementById("iiUrl").value = iiUrl;
};

document.getElementById("loginBtn").addEventListener("click", async () => {
  // ユーザーがクリックすると、ログインプロセスを開始します。
  // 最初にAuthClientを作成します。
  const authClient = await AuthClient.create();

  // 使用すべきログインURLを取得します。
  const iiUrl = document.getElementById("iiUrl").value;

  // authClient.login(...)でインターネットアイデンティティでログインします。これにより、新しいタブが開き
  // ログインプロンプトが表示されます。コードはログインプロセスが完了するまで待機します。
  await new Promise((resolve, reject) => {
    authClient.login({
      identityProvider: iiUrl,
      onSuccess: resolve,
      onError: reject,
    });
  });

  // ここで認証が完了し、authClientからアイデンティティを取得できます：
  const identity = authClient.getIdentity();
  // authClientから取得したアイデンティティを使用して、ICPとやり取りするエージェントを作成します。
  const agent = new HttpAgent({ identity });
  // アプリのインターフェース定義を使用して、アクターを作成し、サービスメソッドを呼び出します。
  const webapp = Actor.createActor(webapp_idl, {
    agent,
    canisterId: webapp_id,
  });
  // whoamiを呼び出して、現在のユーザーのプリンシパル（ユーザーID）を取得します。
  const principal = await webapp.whoami();
  // プリンシパルをページに表示します
  document.getElementById("loginStatus").innerText = principal.toText();
});
```

ブラウザによっては、`http://rdmx6-jaaaa-aaaaa-aaadq-cai.localhost:4943`の値を変更する必要があります：

- Chrome、Firefox: `http://<canister_id>.localhost:4943`

- Safari: `http://localhost:4943?canisterId=<canister_id>`

このコードは以下のことを行います：

- バックエンドアクターとやり取りし、`whoami`メソッドを呼び出します。
- インターネットアイデンティティで認証するために使用される[auth-clientライブラリ](https://www.npmjs.com/package/@dfinity/auth-client)を使用して`AuthClient`を作成します。
- `AuthClient`からアイデンティティを取得します。
- アイデンティティを使用してICPとやり取りするエージェントを作成します。
- アプリのインターフェース定義を使用して、アクターを作成し、アプリのサービスメソッドを呼び出します。

:::info
`ii_integration`以外のプロジェクト名を使用した場合は、コード内のインポートと環境変数をリネームする必要があります。
:::

### ステップ5: フロントエンドカニスターの`index.html`ファイルの編集

以下のコードを`src/ii_integration_frontend/src/index.html`ファイルに挿入します：

```html title="src/ii_integration_frontend/src/index.html"
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width" />
    <title>greet</title>
    <base href="/" />
    <link rel="icon" href="favicon.ico" />
    <link type="text/css" rel="stylesheet" href="main.css" />
  </head>
  <body>
    <main>
      <img src="logo2.svg" alt="DFINITY logo" />
      <br />
      <br />
      <form>
        <button id="login">Login!</button>
      </form>
      <br />
      <form>
        <button id="whoAmI">Who Am I</button>
      </form>
      <section id="principal"></section>
    </main>
  </body>
</html>
```

このコードは、アプリケーションとやり取りするためのシンプルなUIを提供します。

:::info
[このコードのリポジトリを表示](https://github.com/letmejustputthishere/ii_integration_example)して、サンプルをクローンすることもできます。
:::

### ステップ6: プロジェクトをデプロイ

```
dfx deps deploy
dfx deploy
```

### ステップ7: アプリケーションを開く

ウェブブラウザでフロントエンドカニスターのURLにアクセスします。アプリケーションのフロントエンドが表示されます：

![ローカル統合](../_attachments/II_greet_1.png)

### ステップ8: アプリにログイン

IIフロントエンドにリダイレクトされます。ローカルで実行しているため、ローカルの非本番環境のインターネットアイデンティティを使用します。新しいアイデンティティを作成する手順に従ってください。

### ステップ9: ローカルインターネットアイデンティティの作成

- UIから「新規作成」を選択します。

![インターネットアイデンティティ1](../_attachments/II_1.png)

- 次に「パスキーを作成」を選択します。

![インターネットアイデンティティ2](../_attachments/II_2.png)

- プロンプトが表示されたら、現在のデバイスまたは他のデバイスでパスキーを作成する方法を選択します。

![インターネットアイデンティティ3](../_attachments/II_3.png)

- 続行するためにCAPTCHAを入力します。

![インターネットアイデンティティ4](../_attachments/II_4.png)

インターネットアイデンティティが作成されました！画面に表示されるので、安全な場所に記録しておくことをお勧めします。

この番号があなたのインターネットアイデンティティです。この番号とパスキーを使用して、インターネットコンピュータのdappに接続できます。この番号を失うと、それで作成したアカウントも失われます。この番号は秘密ではありませんが、あなただけに固有です。

保存したら、「保存しました、続行」を選択します。

### ステップ10: アプリの機能をテスト

フロントエンドにリダイレクトされたら、「Click me!」ボタンをクリックします。

あなたのインターネットアイデンティティのプリンシパルIDが返されます：

![ローカル統合4](../_attachments/II_greet_2.png)

## ローカルフロントエンド開発

このサンプルのフロントエンドを変更する場合、デプロイされたフロントエンドカニスターではなく、ローカル開発サーバーを使用することをお勧めします。ローカル開発サーバーを使用することで、Hot Module Reloadingが有効になり、フロントエンドに加えた変更を即座に確認できるようになります。

ローカル開発サーバーを起動するには、`npm run start`を実行します。出力には、プロジェクトが実行されているローカルアドレス（例：`127.0.0.1:4943`）が表示されます。

## エンドツーエンドテスト

インターネットアイデンティティの統合のためのエンドツーエンドテストを実行するには、[Internet Identity Playwrightプラグイン](https://github.com/dfinity/internet-identity-playwright)を使用できます。

このプラグインを使用するには、まず[Playwright](https://playwright.dev/)をインストールし、パッケージマネージャーでプラグイン自体をインストールします：

```
# npmでインストール
npm install --save-dev @dfinity/internet-identity-playwright

# pnpmでインストール
pnpm add --save-dev @dfinity/internet-identity-playwright

# yarnでインストール
yarn add -D @dfinity/internet-identity-playwright
```

次に、Playwrightテストファイルにプラグインをインポートします：

```typescript title="e2e/login.spec.ts"
import {testWithII} from '@dfinity/internet-identity-playwright';
```

その後、テストを記述します：

```typescript title="e2e/login.spec.ts"
testWithII('should sign-in with a new user', async ({page, iiPage}) => {
  await page.goto('/');

  await iiPage.signInWithNewIdentity();
});

testWithII('should sign-in with an existing new user', async ({page, iiPage}) => {
  await page.goto('/');

  await iiPage.signInWithIdentity({identity: 10003});
});
```

このテストでは、`iiPage`がインターネットアイデンティティとの認証フローを開始するアプリケーションのページを表します。デフォルトでは、テストは`[data-tid=login-button]`というボタンを探します。このセレクタは、独自のセレクタでカスタマイズできます：

```typescript title="e2e/login.spec.ts"
const loginSelector = '#login';

testWithII('should sign-in with a new user', async ({page, iiPage}) => {
  await page.goto('/');

  await iiPage.signInWithNewIdentity({selector: loginSelector});
});

testWithII('should sign-in with an existing new user', async ({page, iiPage}) => {
  await page.goto('/');

  await iiPage.signInWithIdentity({identity: 10003, selector: loginSelector});
});
```

ローカルレプリカURLとローカルインターネットアイデンティティインスタンスのカニスターIDを提供することで、テストがインターネットアイデンティティの準備が整うのを待つこともできます：

```typescript title="e2e/login.spec.ts"
testWithII.beforeEach(async ({iiPage, browser}) => {
  const url = 'http://127.0.0.1:4943';
  const canisterId = 'rdmx6-jaaaa-aaaaa-aaadq-cai';

  await iiPage.waitReady({url, canisterId});
});
```

タイムアウトパラメーターを設定することで、インターネットアイデンティティが準備完了するまでの待機時間を指定できます：

```typescript title="e2e/login.spec.ts"
testWithII.beforeEach(async ({iiPage, browser}) => {
  const url = 'http://127.0.0.1:4943';
  const canisterId = 'rdmx6-jaaaa-aaaaa-aaadq-cai';
  const timeout = 30000;

  await iiPage.waitReady({url, canisterId, timeout});
});
```

テストが準備できたら、以下のコマンドで実行します：

```
npx playwright test
```

[プラグインのリポジトリで詳細を確認](https://github.com/dfinity/internet-identity-playwright)。

## リソース

- [インターネットアイデンティティダッシュボード](https://identity.ic0.app/)。
- [インターネットアイデンティティ仕様](/docs/current/references/ii-spec)。
- [インターネットアイデンティティGitHubリポジトリ](https://github.com/dfinity/internet-identity)。
- [インターネットアイデンティティの代替フロントエンドオリジン](/docs/current/developer-docs/identity/internet-identity/alternative-origins)。
- [エンドツーエンドテスト用Playwrightプラグイン](https://github.com/dfinity/internet-identity-playwright)。
