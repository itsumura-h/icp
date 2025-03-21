import Cycles "mo:base/ExperimentalCycles";
import Error "mo:base/Error";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Blob "mo:base/Blob";
import Nat8 "mo:base/Nat8";
import Hex "./Hex";
import SHA256 "./SHA256";

module {
  // Only the ecdsa methods in the IC management canister is required here.
  public type IC = actor {
    ecdsa_public_key : ({
      canister_id : ?Principal;
      derivation_path : [Blob];
      key_id : { curve : { #secp256k1 }; name : Text };
    }) -> async ({ public_key : Blob; chain_code : Blob });
    sign_with_ecdsa : ({
      message_hash : Blob;
      derivation_path : [Blob];
      key_id : { curve : { #secp256k1 }; name : Text };
    }) -> async ({ signature : Blob });
  };

  let ic : IC = actor ("aaaaa-aa");

  public func public_key(_caller : Principal) : async [Nat8] {
    let caller = Principal.toBlob(_caller);
    try {
      let { public_key } = await ic.ecdsa_public_key({
        canister_id = null;
        derivation_path = [caller];
        key_id = { curve = #secp256k1; name = "dfx_test_key" };
      });
      return Blob.toArray(public_key);
    } catch (err) {
      let msg = Error.message(err);
      throw Error.reject(msg);
    };
  };

  public func sign(_caller : Principal, message : Text) : async [Nat8] {
    let caller = Principal.toBlob(_caller);
    try {
      let message_hash : Blob = Blob.fromArray(SHA256.sha256(Blob.toArray(Text.encodeUtf8(message))));
      // Cycles.add(25_000_000_000);
      let { signature } = await ic.sign_with_ecdsa({
        message_hash;
        derivation_path = [caller];
        key_id = { curve = #secp256k1; name = "dfx_test_key" };
      });
      return Blob.toArray(signature);
    } catch (err) {
      let msg = Error.message(err);
      throw Error.reject(msg);
    };
  };
};
