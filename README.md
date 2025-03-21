# ICP

## 開発手順
### Motoko
```sh
プロジェクトを作成
dfx new {project name}

# ローカルネットワークを停止
dfx stop

# ローカルネットワークを起動
dfx start --clean --host 0.0.0.0:4943 --background

# .ネットワーク上でキャニスターを作る
dfx canister create counter_backend

# コンパイル
dfx build

# ローカルにデプロイ
dfx deploy -y --network local
```

## キャニスターとフロントエンドの環境構築
```sh
dfx new {project name}
> Motoko
> Vanilla JS
> ✓ Internet Identity

cd {project name}
rm -fr .git
pnpm import package-lock.json
rm package-lock.json
touch pnpm-workspace.yaml
```

pnpm-workspace.yaml
```yaml
packages:
  - src/{project name}-frontend
```

```sh
pnpm create preact
>Project directory
>> {project name}-frontend
> Project language
>> TypeScript
> Use router?
>> No
> Prerender app (SSG)?
>> Yes
> Use ESLint?
>> Yes

rm -fr src/{project name}-frontend
mv {project name}-frontend src/
cd src/{project name}-frontend
pnpm install
pnpm add @dfinity/auth-client @dfinity/agent
```

### フロントエンドの設定
ICPのライブラリをインストール
```sh
pnpm add @dfinity/auth-client @dfinity/agent
```

ハッシュルーティングのためのwouterをインストール
```sh
pnpm add wouter
```

index.tsx
```tsx
import "preact/debug";
import { hydrate, prerender as ssr } from 'preact-iso';
import { Router, Route, Switch } from "wouter";
import { useHashLocation } from "wouter/use-hash-location";
import { HomePage } from "./pages/Home";
import './style.css';

export function App() {
	return (
		<div class="min-h-screen bg-gray-100 max-w-screen mx-auto">
			<Router hook={useHashLocation} base="/">
				<Switch>
					<Route path="/" component={HomePage} />
				</Switch>
			</Router>
		</div>
	);
}

if (typeof window !== 'undefined') {
	hydrate(<App />, document.getElementById('app'));
}

export async function prerender(data) {
	return await ssr(<App {...data} />);
}
```

### tailwindの設定
```sh
pnpm add -D tailwindcss @tailwindcss/vite @tailwindcss/typography autoprefixer daisyui
```

src/style.css
```css
@import "tailwindcss";
@plugin "daisyui";
```

### フロントエンド内の設定を書き換える
Vite5になってから環境変数のロードが動かないので下記を参考に修正する  
https://github.com/ElMassimo/vite-plugin-environment/issues/15#issuecomment-1902831069

vite.config.ts
```ts
import { fileURLToPath, URL } from "url";
import { defineConfig } from "vite";
import preact from "@preact/preset-vite";
import EnvironmentPlugin, {
  type EnvVarDefaults,
} from "vite-plugin-environment";
import tailwindcss from "@tailwindcss/vite";

import { config } from "dotenv";
config({ path: `${process.cwd()}/../../.env` });

const envVarsToInclude = [
  // put the ENV vars you want to expose here
  "DFX_VERSION",
  "DFX_NETWORK",
  "CANISTER_ID_INTERNET_IDENTITY",
  "CANISTER_ID_II_WALLET_FRONTEND",
  "CANISTER_ID_II_WALLET_BACKEND",
  "CANISTER_ID",
  "CANISTER_CANDID_PATH",
];
const esbuildEnvs = Object.fromEntries(
  envVarsToInclude.map(key => [
    `process.env.${key}`,
    JSON.stringify(process.env[key]),
  ])
);

const viteEnvMap: EnvVarDefaults = Object.fromEntries(
  envVarsToInclude.map(entry => [entry, undefined])
);

// https://vitejs.dev/config/
export default defineConfig({
  build: {
    emptyOutDir: true,
  },
  optimizeDeps: {
    esbuildOptions: {
      define: {
        global: "globalThis",
        ...esbuildEnvs,
      },
    },
  },
  server: {
    proxy: {
      "/api": {
        target: "http://127.0.0.1:4943",
        changeOrigin: true,
      },
    },
  },
  plugins: [
    preact({
      prerender: {
        enabled: true,
        renderTarget: "#app",
      },
    }),
    tailwindcss(),
    EnvironmentPlugin(viteEnvMap),
  ],
  resolve: {
    alias: [
      {
        find: "declarations",
        replacement: fileURLToPath(new URL("../declarations", import.meta.url)),
      },
    ],
    dedupe: ["@dfinity/agent"],
  },
});
```

package.json
```json
{
	"name": "auth_login_frontend",
	"private": true,
	"type": "module",
	"scripts": {
		"dev": "vite --mode develop --host 0.0.0.0 --port 3000",
		"build": "vite --mode production build",
		"preview": "vite preview"
	},
	"dependencies": {
		"preact": "^10.25.3",
		"preact-iso": "^2.8.1"
	},
	"devDependencies": {
		"@preact/preset-vite": "^2.9.3",
		"eslint": "^9.17.0",
		"eslint-config-preact": "^1.5.0",
		"typescript": "^5.1.3",
		"vite": "^6.0.4"
	},
	"eslintConfig": {
		"extends": "preact"
	}
}
```

### プロジェクトルートの設定を書き換える

package.json
```json
{
  "engines": {
    "node": ">=16.0.0",
    "npm": ">=7.0.0"
  },
  "name": "{project name}",
  "scripts": {
    "build": "pnpm --filter {project name}-frontend build",
    "prebuild": "pnpm --filter {project name}-frontend prebuild",
    "pretest": "pnpm --filter {project name}-frontend pretest",
    "start": "pnpm --filter {project name}-frontend start",
    "test": "pnpm --filter {project name}-frontend test"
  },
  "type": "module",
  "workspaces": [
    "src/{project name}-frontend"
  ]
}
```

### デプロイ
```sh
dfx stop && dfx start --clean --host 0.0.0.0:4943 --background
dfx deploy -y --network local
```

### キャニスターを呼び出せるようにする
```sh
dfx generate
```
src/declarations ディレクトリからキャニスターを呼び出せるようになる

```tsx
import { useState } from 'preact/hooks';
import { auth_login_backend } from '../declarations/auth_login_backend';

export const Component = () => {
  const [input, setInput] = useState('');
  const [msg, setMsg] = useState('');

  const greet = async () => {
    const greeting = await auth_login_backend.greet(input);
    setMsg(greeting);
  };

  return (
    <>
      <input
        type="text"
        value={input}
        onChange={(e) => setInput(e.target.value)}
      />
      <button onClick={greet}>Greet</button>
      <p>{msg}</p>
    </>
  )
};
```

### Candid UI
```
All canisters have already been created.
Upgraded code for canister t-ecdsa-backend, with canister ID bd3sg-teaaa-aaaaa-qaaba-cai
Deployed canisters.
URLs:
  Frontend canister via browser:
    internet_identity:
      - http://bkyz2-fmaaa-aaaaa-qaaaq-cai.localhost:4943/ (Recommended)
      - http://127.0.0.1:4943/?canisterId=bkyz2-fmaaa-aaaaa-qaaaq-cai (Legacy)
    t-ecdsa-frontend:
      - http://be2us-64aaa-aaaaa-qaabq-cai.localhost:4943/ (Recommended)
      - http://127.0.0.1:4943/?canisterId=be2us-64aaa-aaaaa-qaabq-cai (Legacy)
  Backend canister via Candid interface:
    internet_identity: http://127.0.0.1:4943/?canisterId=br5f7-7uaaa-aaaaa-qaaca-cai&id=bkyz2-fmaaa-aaaaa-qaaaq-cai
    t-ecdsa-backend: http://127.0.0.1:4943/?canisterId=br5f7-7uaaa-aaaaa-qaaca-cai&id=bd3sg-teaaa-aaaaa-qaaba-cai
```

t-ecdsa-backendの  
http://localhost:4943/?canisterId=br5f7-7uaaa-aaaaa-qaaca-cai&id=bd3sg-teaaa-aaaaa-qaaba-cai&ii=http://bkyz2-fmaaa-aaaaa-qaaaq-cai.localhost:4943/

にアクセスするとIIでログインができる  
クエリパラメータのiiパラメータにIIのキャニスターのURLを指定する


## ドキュメント
- [motoko books](https://motoko-book.dev/index.html)

## 開発リソース
### UNCHAIN
- [ ] [ICP Static Site](https://app.unchain.tech/learn/ICP-Static-Site/)
- [ ] [ICP Basic DEX](https://app.unchain.tech/learn/ICP-Basic-DEX/)

### Github
- [ ] [examples](https://github.com/dfinity/examples)
- [ ] [developer-journey](https://internetcomputer.org/docs/current/tutorials/developer-journey/)
- [ ] [awesome-internet-computer](https://github.com/dfinity/awesome-internet-computer#courses-tutorials-and-samples)
- [ ] [MotokoBootCampChallenges](https://github.com/samlinux/MotokoBootCampChallenges)

### dacade
- [ ] [TypeScript Smart Contract 101](https://dacade.org/communities/icp/courses/typescript-smart-contract-101)


[無料でCycleを手に入れる方法](https://medium.com/dfinity/internet-computer-basics-part-2-how-to-get-free-cycles-to-deploy-your-first-dapp-24f6bc5a718b)

[MotokoでQRコードを作る方法](https://medium.com/@ehaussecker/my-first-microservice-on-dfinity-3ac5c142865b)
