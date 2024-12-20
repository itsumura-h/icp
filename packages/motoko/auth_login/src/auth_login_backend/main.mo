import Principal "mo:base/Principal";

actor {
  public query func greet(name : Text) : async Text {
    return "Hello, " # name # "!";
  };

  public query (msg) func getCaller() : async Principal {
    return msg.caller;
  };
};
