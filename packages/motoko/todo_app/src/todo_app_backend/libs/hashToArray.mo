import Iter "mo:base/Iter";
import HashMap "mo:base/HashMap";

module {
  public func hashToArray<K, V>(value : HashMap.HashMap<K, V>) : [(K, V)] {
    return Iter.toArray(value.entries());
  };
};
