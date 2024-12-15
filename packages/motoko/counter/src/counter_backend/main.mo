// main.mo
import Nat "mo:base/Nat";
import Get "./functions/get";
import Set "./functions/set";
import Inc "./functions/inc";
import Storage "storage";

actor Counter {
  let storage = Storage.Storage();

  public query func get() : async Nat {
    return Get.invoke(storage);
  };

  public func set(n : Nat) {
    Set.invoke(storage, n);
  };

  public func inc() {
    Inc.invoke(storage);
  };
};
