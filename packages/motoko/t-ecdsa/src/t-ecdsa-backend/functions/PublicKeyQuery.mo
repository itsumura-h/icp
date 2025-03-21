import Schema "../Storage/Schema";
import Principal "mo:base/Principal";
import Nat8 "mo:base/Nat8";
import Blob "mo:base/Blob";
import ecdsa "./../libs/ecdsa/ecdsa";

module {
  public func invoke(state : Schema.State, caller : Principal) : async Schema.PublicKeyReply {
    // 存在確認
    let publicKey : ?[Nat8] = state.keys.get(caller);
    let existingPublicKey : [Nat8] = switch (publicKey) {
      case (null) {
        // 新規作成
        let publicKey : [Nat8] = await ecdsa.public_key(caller);
        state.keys.put(caller, publicKey);
        publicKey;
      };
      case (?publicKey) {
        publicKey;
      };
    };
    return {
      publicKey = existingPublicKey;
    };
  };
};
