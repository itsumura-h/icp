// functions/get.mo
import Nat "mo:base/Nat";
import Storage "../storage"

module Set {
  public func invoke(storage : Storage.Storage, arg : Nat) {
    storage.set(arg);
  };
};
