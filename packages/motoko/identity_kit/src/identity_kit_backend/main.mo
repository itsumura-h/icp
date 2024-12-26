actor {
  public query func greet(name : Text) : async Text {
    return "Hello, " # name # "!";
  };

  public query (msg) func getPrincipal() : async Principal {
    return msg.caller;
  };
};
