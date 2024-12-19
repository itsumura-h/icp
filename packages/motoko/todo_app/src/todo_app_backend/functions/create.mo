import Time "mo:base/Time";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Int "mo:base/Int";
import Storage "../storage/storage";
import Schema "../storage/schema";

module {
  public func invoke(storage : Storage.Storage, userId : Principal, content : Text) : Text {
    let currentTime = Time.now();
    let id = Principal.toText(userId) # Int.toText(currentTime);

    let data : Schema.TodoSchema = {
      id = id;
      var content = content;
      var status = #Created;
      createdAt = currentTime;
      var updatedAt = currentTime;
    };

    storage.create(userId, data);
    return id;
  };
};
