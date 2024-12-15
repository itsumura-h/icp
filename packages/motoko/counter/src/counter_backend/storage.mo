// storage.mo
import Nat "mo:base/Nat";

module {
  public class Storage() {
    private var count : Nat = 0;

    public func get() : Nat {
      count;
    };

    public func set(arg : Nat) {
      count := arg;
    };
  };
};
