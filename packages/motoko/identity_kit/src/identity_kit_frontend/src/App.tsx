import { useState } from 'react';
import { HttpAgent } from "@dfinity/agent";
import { ConnectWallet } from "@nfid/identitykit/react";

function App() {
  const [inputMsg, setInputMsg] = useState("");
  const [identityKitBackendAgent, setIdentityKitBackendAgent] = useState<HttpAgent | undefined>()
  const [principal, setPrincipal] = useState<string | undefined>()

  const getPrincipal = async () => {
    const _principal = await identityKitBackendAgent?.getPrincipal()
    setPrincipal(_principal?.toString())
  }

  return (
    <main className="min-w-screen min-h-screen p-4">
      <article className="p-4">
        <section className='p-4 bg-gray-100'>
          <ConnectWallet />
        </section>
      </article>
      <article className='p-4'>
        <section className='p-4 bg-gray-100'>
          <div className='p-4'>
            <button className='btn bg-gray-300' onClick={getPrincipal}>getPrincipal</button>
          </div>
          <div className='p-4'>
            <p>{principal}</p>
          </div>
        </section>
      </article>
    </main>
  );
}

export default App;
