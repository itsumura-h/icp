import Text "mo:base/Text";
import Principal "mo:base/Principal";
import Schema "./Storage/Schema";
import Storage "./Storage/Storage";
import PublicKeyQuery "./functions/PublicKeyQuery";
import Sign "./functions/Sign";

actor {
  public query (msg) func get_caller() : async Principal {
    return msg.caller;
  };

  private let storage = Storage.Storage();

  public shared (msg) func publicKeyQuery() : async Schema.PublicKeyReply {
    return await PublicKeyQuery.invoke(storage.state, msg.caller);
  };

  public shared (msg) func sign(message : Text) : async Schema.SignatureReply {
    return await Sign.invoke(msg.caller, message);
  };
};
