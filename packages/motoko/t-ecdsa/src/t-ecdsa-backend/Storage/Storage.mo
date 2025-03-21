import Schema "Schema";
import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Nat8 "mo:base/Nat8";

module {
  public class Storage() {
    // 初期値
    public var state : Schema.State = {
      keys = HashMap.HashMap<Principal, [Nat8]>(0, Principal.equal, Principal.hash);
      config = {
        env = #Development;
        keyName = "dfx_test_key";
        signCycles = 0;
      };
    };
  };
};
