https://internetcomputer.org/docs/current/developer-docs/developer-tools/off-chain/agents/overview

https://github.com/dfinity/portal/blob/master/docs/developer-docs/developer-tools/off-chain/agents/overview.mdx

---
キーワード: [中級, エージェント, 概要, JavaScript, Rust, Node.js]
---

# ICPエージェントとは？

インターネットコンピュータ（ICP）エコシステムでは、ICPの公開インターフェースへの呼び出しを行うために使用されるライブラリは**エージェント**と呼ばれます。エージェントにはいくつかの重要な役割があり、お好みのプログラミング言語で作業する際に便利です。

ローカルマシンまたはインターネットコンピュータ上でカニスターが実行されている場合、カニスターのスマートコントラクトとやり取りする主な方法は2つです。
1つは、**エージェント**を使用してv2 APIを介してカニスターと通信する方法で、インターフェース仕様に従います。もう1つは、カニスターのHTTPSインターフェースを使用する方法です。

スマートコントラクトは、Candidインターフェース宣言言語（IDL）を使用して独自のAPIを定義でき、公開APIを介して呼び出しに応答します。

ICPは2種類の呼び出しをサポートしています - `query`と`update`です。クエリは高速で状態を変更することはありません。更新はコンセンサスを経て行われ、完了するまでに約2〜4秒かかります。

更新にかかる遅延のため、アプリケーションのパフォーマンスモデルでは、更新を非同期で早期に行うことが推奨されます。事前に更新を行い、カニスターのメモリに「キャッシュ」しておけば、ユーザーはそのデータを要求したときにより良い体験を得られます。同様に、アプリケーションが更新を行う必要がある場合、更新が行われている間はインタラクションをブロックしないことが最良です。実行可能な場合は、**楽観的レンダリング**を使用し、呼び出しがすでに成功したかのようにアプリケーションを進めます。

## 利用可能なエージェント

このセクションでは、以下のエージェントについて言語別に説明します：

- JavaScript / TypeScript
  - [DFINITYのJavaScript/TypeScriptエージェント](/docs/current/developer-docs/developer-tools/off-chain/agents/javascript-agent)
- Rust
  - [DFINITYのRustエージェント](/docs/current/developer-docs/developer-tools/off-chain/agents/rust-agent)

これらに加えて、いくつかの他のコミュニティサポートのエージェントも存在します。これらのエージェントは、メンテナンスされていない場合やセキュリティレビューが行われていない可能性があるため、使用する前に現在の状況を確認することをお勧めします：

- .NET
  - [`ICP.NET` by Gekctek](https://github.com/Gekctek/ICP.NET)
- Dart
  - [`agent_dart` by AstroX](https://github.com/AstroxNetwork/agent_dart)（Flutterによるモバイル開発をサポート）
  - [`ic_dart_tools` by Levi Feldman](https://github.com/levifeldman/ic_tools_dart)
- Go
  - [`IC-Go` by MixLabs](https://github.com/mix-labs/IC-Go)
  - [`agent-go` by Aviate Labs](https://github.com/aviate-labs/agent-go)
- Java
  - [`ic4j-agent` by IC4J](https://github.com/ic4j/ic4j-agent)（Androidをサポート）
- Python
  - [`ic-py` by Rocklabs](https://github.com/rocklabs-io/ic-py)
- C
  - [`agent-c` by Zondax](https://github.com/Zondax/icp-client-cpp)（IC RustエージェントのCラッパー）
- Ruby
  - [`ic_agent` by Terry.Tu](https://github.com/tuminfei/ic_agent)

他の言語でエージェントを構築したい場合は、[https://dfinity.org/grants](https://dfinity.org/grants)を通じてお問い合わせください。

## エージェントの役割

### データの構造化

インターネットコンピュータへの`call`は、2つの一般的な形式 - `update`または`query` - を取ります。**エージェント**は`/api/v2/canister/<effective_canister_id>/call`に`POST`リクエストを送信し、以下のコンポーネントを含めます：

- `request_type`
- 認証
  - `sender`, `nonce`, および `ingress_expiry`
- `canister_id`
- `method_name`
- `request_id` - `update`リクエストタイプの呼び出しに必要
- `arg` - 残りのペイロード

カニスターのCandidインターフェースを知っていることにより、**エージェント**は`arg`をクライアントアプリケーションからのデータで構築し、呼び出すメソッドのCandidインターフェースに一致することを確認します。上記のすべてのコンポーネントは、証明書として組み立てられ、CBORエンコードされたバッファに変換されます。

更新リクエストの場合、エージェントは残りのフィールドもハッシュし、ユニークな`request_id`として渡します。この`request_id`は、ICPが更新に関するコンセンサスに到達するまでポーリングに使用されます。

**エージェント**は、CBORエンコードされた証明書を`POST`リクエストのボディに添付します。カニスターはそのリクエストを非同期に処理し、その後**エージェント**は`read_state`リクエストでポーリングを開始し、カニスターの応答が準備できるまで待機します。

### データのデコード

ICPからデータが返されると、**エージェント**はペイロードから証明書を取得し、検証します。この証明書は、NNSサブネットの公開`rootKey`を使用して本物であることが確認できます。ネットワークはCBORエンコードされたバッファで応答し、**エージェント**はそれをデコードして、意味論的な言語固有の型を使用して有用な構造に変換します。例えば、カニスターから返される型が`text`の場合、それはJavaScriptの`string`に変換されます。

### 認証の管理

インターネットコンピュータへの呼び出しには、常に暗号的なアイデンティティが添付されている必要があります。そのアイデンティティは、**匿名**または**認証済み**で、暗号的署名を使用します。アイデンティティが必要なため、カニスターは呼び出しに添付されたアイデンティティを使用してその呼び出しにどのように応答するかを決定できます。これにより、契約が他の目的でこれらのアイデンティティを使用することが可能になります。

#### 受け入れられるアイデンティティ

ICPは、以下のタイプの署名を使用して呼び出しを受け入れます：

- [Ed25519](https://ed25519.cr.yp.to/index.html)
- [ECDSA](https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.186-4.pdf)
  - 曲線P-256（`secp256r1`としても知られる）で、ハッシュ関数として`SHA-256`を使用。
  - Koblitz曲線`secp256k1`。

これらのスキームに対してプレーンな署名がサポートされています。

これらのアイデンティティを`principal`としてエンコードする際、エージェントは接尾辞バイトを添付して、アイデンティティが自己認証されているか、匿名かを示します。

上記の曲線のいずれかを使用した自己認証アイデンティティには接尾辞として2が付きます。

匿名アイデンティティは1バイトで4が付与され、テキストエンコードでは`"2vxsx-fae"`に解決されます。
