// functions/get.mo
import Nat "mo:base/Nat";
import Storage "../storage"

module Get {
  public func invoke(storage : Storage.Storage) : Nat {
    return storage.get();
  };
};
