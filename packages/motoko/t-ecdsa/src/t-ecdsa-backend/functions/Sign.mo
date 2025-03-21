import Principal "mo:base/Principal";
import Debug "mo:base/Debug";
import Schema "./../Storage/Schema";
import ecdsa "./../libs/ecdsa/ecdsa";

module {
  public func invoke(caller : Principal, message : Text) : async Schema.SignatureReply {
    Debug.print("=== sign ===");
    Debug.print("caller: " # Principal.toText(caller));
    Debug.print("message: " # message);
    let signature = await ecdsa.sign(caller, message);
    return {
      signature = signature;
    };
  };
};
