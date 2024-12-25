import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Storage "../storage/storage";

module {
  public func invoke(storage : Storage.Storage, userId : Principal, id : Text) {
    let optTaskData = storage.getByTaskId(userId, id);
    var taskData = switch (optTaskData) {
      case (null) {
        return;
      };
      case (?taskData) {
        taskData;
      };
    };

    taskData.status := #InProgress;
    storage.update(userId, taskData);
  };
};
