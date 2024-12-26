import { useState, useEffect } from 'react';
import { useAgent } from "@nfid/identitykit/react";
import { Actor, HttpAgent } from "@dfinity/agent";
import { ConnectWallet } from "@nfid/identitykit/react";

function App() {
  const [inputMsg, setInputMsg] = useState("");
  const authenticatedAgent = useAgent();

  return (
    <main className="min-w-screen min-h-screen p-4">
      <article className="p-4">
        <section className='p-4 bg-gray-100'>
          <ConnectWallet />
        </section>
      </article>
    </main>
  );
}

export default App;
