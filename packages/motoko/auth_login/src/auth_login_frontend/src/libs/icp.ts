import { useState, useEffect} from "preact/hooks"
import { AuthClient} from "@dfinity/auth-client"
import { Identity, ActorSubclass, HttpAgent } from '@dfinity/agent';
import {
  canisterId as authLoginBackendCanisterId,
  createActor as createAuthLoginBackendActor,
} from "../../../declarations/auth_login_backend"
import {_SERVICE as AuthLoginBackendService} from "../../../declarations/auth_login_backend/auth_login_backend.did"
import {
  canisterId as internetIdentityCanisterId,
  createActor as createInternetIdentityActor,
} from "../../../declarations/internet_identity"
import {_SERVICE as InternetIdentityService} from "../../../declarations/internet_identity/internet_identity.did"

export const useIcp = ()=>{
  const [authClient, setAuthClient] = useState<AuthClient | null>(null)
  const [isLogin, setIsLogin] = useState(false)
  const [identityState, setIdentityState] = useState<Identity | null>(null)
  const [authLoginActorState, setAuthLoginActorState] = useState<ActorSubclass<AuthLoginBackendService>>(
    createAuthLoginBackendActor(authLoginBackendCanisterId)
  )
  const [internetIdentityActorState, setInternetIdentityActorState] = useState<ActorSubclass<InternetIdentityService>>(
    createInternetIdentityActor(internetIdentityCanisterId)
  )

  const createActor=async(authClient:AuthClient)=>{
    setIsLogin(true)
    const idendity = authClient.getIdentity()
    setIdentityState(idendity)
    const agent = await HttpAgent.create({
      identity: idendity,
    })

    const authLoginActor = createAuthLoginBackendActor(authLoginBackendCanisterId, {
      agent,
    })
    setAuthLoginActorState(authLoginActor)

    const internetIdentityActor = createInternetIdentityActor(internetIdentityCanisterId, {
      agent,
    });
    setInternetIdentityActorState(internetIdentityActor)
  }

  useEffect(()=>{
    (async()=>{
      const authClient = await AuthClient.create()
      setAuthClient(authClient)
      if(await authClient.isAuthenticated()){
        createActor(authClient)
      }
    })()
  },[])

  const icLogin=async()=>{
    if(isLogin) return
    authClient.login({
      maxTimeToLive: BigInt(7 * 24 * 60 * 60 * 1000 * 1000 * 1000),
      identityProvider: `http://${internetIdentityCanisterId}.localhost:4943`,
      onSuccess: async() => {
        createActor(authClient)
      }
    })
  }

  const icLogout=async()=>{
    if(!isLogin) return
    await authClient.logout()
    setIsLogin(false)
    setIdentityState(null)
    setAuthLoginActorState(createAuthLoginBackendActor(authLoginBackendCanisterId))
    setInternetIdentityActorState(createInternetIdentityActor(internetIdentityCanisterId))
  }

  
  return {
    isLogin:isLogin,
    identity: identityState,
    icLogin,
    icLogout,
    authLoginActor: authLoginActorState,
    internetIdentityActor: internetIdentityActorState,
  }
}
