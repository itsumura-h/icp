# ICP

## 開発手順
```sh
# ローカルネットワークを停止
dfx stop

# ローカルネットワークを起動
dfx start --clean --host 0.0.0.0:4943 --background

# .ネットワーク上でキャニスターを作る
dfx canister create counter_backend

# コンパイル
dfx build

# ローカルにデプロイ
dfx deploy --network local
```

## ドキュメント
- [motoko books](https://motoko-book.dev/index.html)

## 開発リソース
### UNCHAIN
- [ ] [ICP Static Site](https://app.unchain.tech/learn/ICP-Static-Site/)
- [ ] [ICP Basic DEX](https://app.unchain.tech/learn/ICP-Basic-DEX/)

### Github
- [ ] [examples](https://github.com/dfinity/examples)
- [ ] [awesome-internet-computer](https://github.com/dfinity/awesome-internet-computer#courses-tutorials-and-samples)
- [ ] [MotokoBootCampChallenges](https://github.com/samlinux/MotokoBootCampChallenges)

### dacade
- [ ] [TypeScript Smart Contract 101](https://dacade.org/communities/icp/courses/typescript-smart-contract-101)


[無料でCycleを手に入れる方法](https://medium.com/dfinity/internet-computer-basics-part-2-how-to-get-free-cycles-to-deploy-your-first-dapp-24f6bc5a718b)

[MotokoでQRコードを作る方法](https://medium.com/@ehaussecker/my-first-microservice-on-dfinity-3ac5c142865b)
