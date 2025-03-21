import { useState } from "preact/hooks";
import { type Principal } from '@dfinity/principal';
import { useIcp } from "../hooks/useIcp";
import { createPublicClient, http, type Address, toBytes, hashMessage, serializeSignature, fromBytes, verifyMessage } from "viem"
import { sepolia } from "viem/chains"
import { computeAddress, convert64ByteSignature } from "../libs/icpToEth";

export const HomePage = () => {
  const { isLogin, identity, icLogin, icLogout, tEcdsaBackendActor } = useIcp();
  const principal = identity?.getPrincipal().toText();
  const [publicKey, setPublicKey] = useState("");
  const [signMessage, setSignMessage] = useState("");
  const [signature, setSignature] = useState("");
  const [valid, setValid] = useState(false);

  const getPublicKey = async () => {
    const publicKeyReply = await tEcdsaBackendActor.publicKeyQuery();
    console.log(publicKeyReply);
    console.log(typeof publicKeyReply);
    const uint8ArrayPublicKey = new Uint8Array(publicKeyReply.publicKey);
    const publicKey = computeAddress(uint8ArrayPublicKey);
    console.log({ publicKey });
    setPublicKey(publicKey);
  };

  const sign = async () => {
    console.log("=== sign ===")
    const signatureReply = await tEcdsaBackendActor.sign(signMessage);
    const uint8ArraySignature = new Uint8Array(signatureReply.signature);
    console.log({ uint8ArraySignature });
    const { r, s, v } = convert64ByteSignature(uint8ArraySignature);
    console.log({ r, s, v });
    const signature = serializeSignature({
      r: r as Address,
      s: s as Address,
      v: BigInt(v),
    });
    console.log({ signature });
    setSignature(signature);
  };

  const verify = async () => {
    console.log("=== verify ===")
    console.log({ publicKey });
    console.log({ signMessage });
    console.log({ signature });
    const valid = await verifyMessage({
      address: publicKey as Address,
      message: signMessage,
      signature: signature as Address,
    })
    console.log({ valid });
    setValid(valid);
  }

  return (
    <main>
      <article>
        {isLogin ? (
          <>
            <button onClick={icLogout}>
              ログアウト
            </button>
          </>
        ) : (
          <button onClick={icLogin}>ログイン</button>
        )}
        <p>principal: {principal}</p>
        <hr />
        <button onClick={getPublicKey}>getPublicKey</button>
        <p>EVM publicKey: {publicKey}</p>
        <hr />
        <input type="text" placeholder="sign message" value={signMessage} onChange={(e) => setSignMessage((e.target as HTMLInputElement).value)} />
        <button onClick={sign}>sign</button>
        <div>
          signature:
          <textarea disabled value={signature} />
        </div>
        <button onClick={verify}>verify</button>
        <p>valid: {valid ? "true" : "false"}</p>
      </article>
    </main>
  );
};
