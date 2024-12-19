import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Text "mo:base/Text";
import Buffer "mo:base/Buffer";
import Storage "../storage/storage";
import Schema "../storage/schema";
import ResponseTypes "../responseTypes";

module {
  public func invoke(storage : Storage.Storage, userId : Principal) : ResponseTypes.GetByUserIdResponseType {
    var response : ResponseTypes.GetByUserIdResponseType = {
      userId = "";
      data = [];
    };

    let optTodoData : ?HashMap.HashMap<Text, Schema.TodoSchema> = storage.getByUserId(userId);
    let existingUserData = switch (optTodoData) {
      case (null) {
        return response;
      };
      case (?existingUserData) {
        existingUserData;
      };
    };

    let newData = Buffer.Buffer<ResponseTypes.GetByTaskIdResponseType>(0);
    for ((id, data) in existingUserData.entries()) {
      let status = switch (data.status) {
        case (#Created) { "created" };
        case (#InProgress) { "inProgress" };
        case (#Completed) { "completed" };
      };

      let editedData = {
        id = id;
        content = data.content;
        status = status;
        createdAt = data.createdAt;
        updatedAt = data.updatedAt;
      };

      newData.add(editedData);
    };

    response := {
      userId = Principal.toText(userId);
      data = Buffer.toArray(newData);
    };

    return response;
  };
};
