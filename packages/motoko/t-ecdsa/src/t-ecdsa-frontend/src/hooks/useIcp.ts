import { useState, useEffect } from "preact/hooks";
import { AuthClient } from "@dfinity/auth-client";
import { Identity, ActorSubclass, HttpAgent } from "@dfinity/agent";
import {
  canisterId as internetIdentityCanisterId,
  createActor as createInternetIdentityActor,
} from "../../../declarations/internet_identity";
import { _SERVICE as InternetIdentityService } from "../../../declarations/internet_identity/internet_identity.did";
import {
  canisterId as tEcdsaBackendCanisterId,
  createActor as createTEcdsaBackendActor,
} from "../../../declarations/t-ecdsa-backend";
import { _SERVICE as TEcdsaBackendService } from "../../../declarations/t-ecdsa-backend/t-ecdsa-backend.did";

export const useIcp = () => {
  const [authClient, setAuthClient] = useState<AuthClient | null>(null);
  const [isLogin, setIsLogin] = useState(false);
  const [identityState, setIdentityState] = useState<Identity | null>(null);
  const [internetIdentityActorState, setInternetIdentityActorState] = useState<
    ActorSubclass<InternetIdentityService>
  >(createInternetIdentityActor(internetIdentityCanisterId));
  const [tEcdsaBackendActorState, setTEcdsaBackendActorState] = useState<
    ActorSubclass<TEcdsaBackendService>
  >(createTEcdsaBackendActor(tEcdsaBackendCanisterId));

  const createActor = async (authClient: AuthClient) => {
    setIsLogin(true);
    const idendity = authClient.getIdentity();
    setIdentityState(idendity);
    const agent = await HttpAgent.create({
      identity: idendity,
    });

    const internetIdentityActor = createInternetIdentityActor(
      internetIdentityCanisterId,
      {
        agent,
      }
    );
    setInternetIdentityActorState(internetIdentityActor);

    const tEcdsaBackendActor = createTEcdsaBackendActor(
      tEcdsaBackendCanisterId,
      {
        agent,
      }
    );
    setTEcdsaBackendActorState(tEcdsaBackendActor);
  };

  useEffect(() => {
    (async () => {
      const authClient = await AuthClient.create();
      setAuthClient(authClient);
      if (await authClient.isAuthenticated()) {
        createActor(authClient);
      }
    })();
  }, []);

  const icLogin = async () => {
    if (isLogin) return;
    authClient.login({
      maxTimeToLive: BigInt(7 * 24 * 60 * 60 * 1000 * 1000 * 1000),
      identityProvider: `http://${internetIdentityCanisterId}.localhost:4943`,
      onSuccess: async () => {
        createActor(authClient);
      },
    });
  };

  const icLogout = async () => {
    if (!isLogin) return;
    await authClient.logout();
    setIsLogin(false);
    setIdentityState(null);
    // setInternetIdentityActorState(
    //   createInternetIdentityActor(internetIdentityCanisterId)
    // );
  };

  return {
    isLogin: isLogin,
    identity: identityState,
    icLogin,
    icLogout,
    internetIdentityActor: internetIdentityActorState,
    tEcdsaBackendActor: tEcdsaBackendActorState,
  };
};
