import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Time "mo:base/Time";
import HashMap "mo:base/HashMap";

module {
  public type StatusSchema = {
    #Created;
    #InProgress;
    #Completed;
  };

  public type TodoSchema = {
    id : Text;
    var content : Text;
    var status : StatusSchema;
    createdAt : Time.Time;
    var updatedAt : Time.Time;
  };

  public type TodoMapSchema = HashMap.HashMap<Principal, HashMap.HashMap<Text, TodoSchema>>;
};
