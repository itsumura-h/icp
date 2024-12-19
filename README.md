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

### TypeScript
```sh
プロジェクトを作成
pnpm dlx azle new {project name}

# ローカルネットワークを停止
dfx stop

# ローカルネットワークを起動
dfx start --clean --host 0.0.0.0:4943 --background

# コンパイル
dfx build

# ローカルにデプロイ
dfx deploy --network local
```

### Python
```sh
# Python環境を構築
pipenv install kybra
python -m kybra install-dfx-extension

# ローカルネットワークを停止
dfx stop

# ローカルネットワークを起動
dfx start --clean --host 0.0.0.0:4943 --background
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
