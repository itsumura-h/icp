import {
  keccak256,
  hashMessage,
  serializeSignature,
  fromBytes,
  toBytes,
} from "viem";
/**
 * EIP-55 に準拠したチェックサム付きアドレスを生成する関数
 *
 * @param address - 小文字の 16 進数アドレス（"0x" プレフィックス付き）
 * @returns チェックサム付きアドレス
 */
function toChecksumAddress(address: string): string {
  const lowerAddress = address.toLowerCase().replace(/^0x/, "");
  // アドレスのハッシュ値を計算（"0x" を付与して keccak256 計算）
  const hash = keccak256(new TextEncoder().encode(lowerAddress)).slice(2);
  let checksumAddress = "0x";

  for (let i = 0; i < lowerAddress.length; i++) {
    const char = lowerAddress[i];
    // ハッシュの該当ニブルが 8 以上なら大文字に変換
    checksumAddress += parseInt(hash[i], 16) >= 8 ? char.toUpperCase() : char;
  }
  return checksumAddress;
}

/**
 * Uint8Array 型の公開鍵から Ethereum アドレスを計算する関数
 *
 * @param publicKey - Uncompressed 公開鍵のバイト列（先頭が 0x04 の場合はそれを除去）
 * @returns チェックサム付き Ethereum アドレス
 */
export function computeAddress(publicKey: Uint8Array): string {
  // Uncompressed 公開鍵の場合、先頭バイト 0x04 を除去
  const keyWithoutPrefix =
    publicKey[0] === 0x04 ? publicKey.slice(1) : publicKey;

  // keccak256 を計算（Uint8Array を直接渡す）
  const hash = keccak256(keyWithoutPrefix);
  // hash は "0x" + 64 文字の 16 進数文字列なので、下位 20 バイト（40 文字）を抽出
  const rawAddress = "0x" + hash.slice(-40);

  return toChecksumAddress(rawAddress);
}

/**
 * 64バイトの署名データを32バイトのrとsとvに変換する関数
 * @param sig - 64バイトの署名データ
 * @returns 32バイトのrとsとv
 */
export function convert64ByteSignature(sig: Uint8Array): {
  r: string;
  s: string;
  v: number;
} {
  if (sig.length !== 64) {
    throw new Error("署名の長さが正しくありません。");
  }

  // r と s に分割
  const rBytes = sig.slice(0, 32);
  const sBytes = sig.slice(32, 64);

  // sの先頭バイトからvを復元（最上位ビットがvの情報）
  const firstByte = sBytes[0];
  const v = (firstByte & 0x80) !== 0 ? 28 : 27;

  // sの先頭バイトから最上位ビットをクリア
  const normalizedSBytes = new Uint8Array(sBytes);
  normalizedSBytes[0] = firstByte & 0x7f;

  // Uint8Arrayを16進数文字列に変換（'0x'プレフィックス付き）
  const toHex = (bytes: Uint8Array) =>
    "0x" +
    Array.from(bytes)
      .map(b => b.toString(16).padStart(2, "0"))
      .join("");

  const r = toHex(rBytes);
  const s = toHex(normalizedSBytes);

  return { r, s, v };
}
