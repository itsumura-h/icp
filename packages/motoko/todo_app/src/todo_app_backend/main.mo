import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Storage "storage/storage";
import Create "functions/create";
import UpdateContent "functions/updateContent";
import UpdateInProgress "functions/updateInProgress";
import UpdateCompleted "functions/updateCompleted";
import GetByTaskId "functions/getByTaskId";
import GetByUserId "functions/getByUserId";
import ResponseTypes "responseTypes";

actor {
  private let storage = Storage.Storage();

  public func create(userId : Principal, content : Text) : async Text {
    return Create.invoke(storage, userId, content);
  };

  public func updateContent(userId : Principal, id : Text, content : Text) : async Text {
    return UpdateContent.invoke(storage, userId, id, content);
  };

  public func updateInProgress(userId : Principal, id : Text) {
    return UpdateInProgress.invoke(storage, userId, id);
  };

  public func updateCompleted(userId : Principal, id : Text) {
    return UpdateCompleted.invoke(storage, userId, id);
  };

  public query func getByTaskId(userId : Principal, id : Text) : async ResponseTypes.GetByTaskIdResponseType {
    return GetByTaskId.invoke(storage, userId, id);
  };

  public query func getByUserId(userId : Principal) : async ResponseTypes.GetByUserIdResponseType {
    return GetByUserId.invoke(storage, userId);
  };
};
