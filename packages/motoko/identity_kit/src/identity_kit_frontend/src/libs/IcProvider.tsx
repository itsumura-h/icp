import "@nfid/identitykit/react/styles.css"
import { IdentityKitProvider } from "@nfid/identitykit/react"
import { IdentityKitAuthType } from "@nfid/identitykit"
import { canisterId as identityKitBackendCanisterId } from "../../../declarations/identity_kit_backend"
import { canisterId as internetIdentityCanisterId } from "../../../declarations/internet_identity"

export const IcProvider = ({ children }) => {
  return (
    <IdentityKitProvider
      authType={IdentityKitAuthType.DELEGATION}
      signerClientOptions={{
        targets: [identityKitBackendCanisterId, internetIdentityCanisterId]
      }}
    >
      {children}
    </IdentityKitProvider>
  )
}
