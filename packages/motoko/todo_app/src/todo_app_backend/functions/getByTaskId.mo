import Text "mo:base/Text";
import Storage "../storage/storage";
import Schema "../storage/schema";
import ResponseTypes "../responseTypes";

module {
  public func invoke(storage : Storage.Storage, userId : Principal, taskId : Text) : ResponseTypes.GetByTaskIdResponseType {
    var response : ResponseTypes.GetByTaskIdResponseType = {
      id = "";
      content = "";
      status = "";
      createdAt = 0;
      updatedAt = 0;
    };

    let optTaskData : ?Schema.TodoSchema = storage.getByTaskId(userId, taskId);
    let existingTaskData = switch (optTaskData) {
      case (null) {
        return response;
      };
      case (?existingTaskData) {
        existingTaskData;
      };
    };

    let status = switch (existingTaskData.status) {
      case (#Created) {
        "created";
      };
      case (#InProgress) {
        "in_progress";
      };
      case (#Completed) {
        "completed";
      };
    };

    response := {
      id = existingTaskData.id;
      content = existingTaskData.content;
      status = status;
      createdAt = existingTaskData.createdAt;
      updatedAt = existingTaskData.updatedAt;
    };
    return response;
  };
};
