import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Storage "../storage/storage";
import Schema "../storage/schema";

module {
  public func invoke(storage : Storage.Storage, userId : Principal, id : Text, content : Text) : Text {
    let optExistingData : ?Schema.TodoSchema = storage.getByTaskId(userId, id);
    var existingData : Schema.TodoSchema = switch (optExistingData) {
      case (null) {
        return "";
      };
      case (?existingData) {
        existingData;
      };
    };

    existingData.content := content;
    existingData.updatedAt := Time.now();

    storage.update(userId, existingData);
    return id;
  };
};
