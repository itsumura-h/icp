import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Nat64 "mo:base/Nat64";
import Text "mo:base/Text";
import Nat8 "mo:base/Nat8";

module {
  public type PublicKeyReply = {
    publicKey : [Nat8];
  };

  public type SignatureReply = {
    signature : [Nat8];
  };

  public type Environment = {
    #Development;
    #Staging;
    #Production;
  };

  public type Config = {
    env : Environment;
    keyName : Text;
    signCycles : Nat64;
  };

  public type State = {
    keys : HashMap.HashMap<Principal, [Nat8]>;
    config : Config;
  };
};
