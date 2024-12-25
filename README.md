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
  - src/auth_login_frontend
```

```sh
pnpm create preact
>Project directory
>> {project name}_frontend
> Project language
>> TypeScript
> Use router?
>> Yes
> Prerender app (SSG)?
>> No
> Use ESLint?
>> Yes

mv src/{project name}_frontend src/{project name}_frontend.bk
cp -r {project name}_frontend src/
rm -fr {project name}_frontend
pnpm install
```

### フロントエンド内の設定を書き換える
vite.config.ts
```ts
import { fileURLToPath, URL } from 'url';
import { defineConfig } from 'vite';
import EnvironmentPlugin from 'vite-plugin-environment';
import preact from '@preact/preset-vite';
import dotenv from 'dotenv';

dotenv.config({ path: '../../.env' });

export default defineConfig({
  build: {
    emptyOutDir: true,
  },
  optimizeDeps: {
    esbuildOptions: {
      define: {
        global: "globalThis",
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
  publicDir: "assets",
  plugins: [
    preact(),
    EnvironmentPlugin("all", { prefix: "CANISTER_" }),
    EnvironmentPlugin("all", { prefix: "DFX_" }),
  ],
  resolve: {
		alias:{
			"declarations": fileURLToPath(
				new URL("../declarations", import.meta.url)
			),
			"react": "preact/compat",
			"react-dom": "preact/compat",
		},
    dedupe: ['@dfinity/agent'],
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
  "name": "auth_login",
  "scripts": {
    "build": "pnpm --filter auth_login_frontend build",
    "prebuild": "pnpm --filter auth_login_frontend prebuild",
    "pretest": "pnpm --filter auth_login_frontend prebuild",
    "start": "pnpm --filter auth_login_frontend start",
    "test": "pnpm --filter auth_login_frontend test"
  },
  "type": "module",
  "workspaces": [
    "src/auth_login_frontend"
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
        onChange={(e) => setInput(e.currentTarget.value)}
      />
      <button onClick={greet}>Greet</button>
      <p>{msg}</p>
    </>
  )
};
```


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
