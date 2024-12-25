import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Text "mo:base/Text";
import Schema "./schema";

module {
  public class Storage() {
    // 初期値
    private var todoDatabase : Schema.TodoMapSchema =
      HashMap.HashMap<Principal, HashMap.HashMap<Text, Schema.TodoSchema>>(0, Principal.equal, Principal.hash);


    public func getByUserId(userId : Principal) : ?HashMap.HashMap<Text, Schema.TodoSchema> {
      return todoDatabase.get(userId);
    };


    public func getByTaskId(userId : Principal, id:Text) : ?Schema.TodoSchema {
      let optExistingUserData : ?HashMap.HashMap<Text, Schema.TodoSchema> = todoDatabase.get(userId);
      let existingUserData : HashMap.HashMap<Text, Schema.TodoSchema> =
        switch (optExistingUserData) {
          case (null) {
            return null;
          };
          case (?existingUserData) {
            existingUserData;
          };
        };
      return existingUserData.get(id);
    };


    public func create(userId : Principal, data : Schema.TodoSchema) {
      let optExistingData : ?HashMap.HashMap<Text, Schema.TodoSchema> = todoDatabase.get(userId);
      let existingData : HashMap.HashMap<Text, Schema.TodoSchema> =
        switch (optExistingData) {
          case (null) {
            HashMap.HashMap<Text, Schema.TodoSchema>(0, Text.equal, Text.hash);
          };
          case (?existingData) {
            existingData;
          };
        };

      existingData.put(data.id, data);
      todoDatabase.put(userId, existingData);
    };


    public func update(userId : Principal, data:Schema.TodoSchema) {
      let optExistingUserData : ?HashMap.HashMap<Text, Schema.TodoSchema> = todoDatabase.get(userId);
      let existingUserData : HashMap.HashMap<Text, Schema.TodoSchema> =
        switch (optExistingUserData) {
          case (null) {
            return;
          };
          case(?existingData){
            existingData;
          };
        };
      
      let optTargetData : ?Schema.TodoSchema = existingUserData.get(data.id);
      let targetData : Schema.TodoSchema =
        switch (optTargetData) {
          case (null) {
            return;
          };
          case (?targetData) {
            targetData
          };
        };

      let _ = existingUserData.replace(data.id, targetData);
      let _ = todoDatabase.replace(userId, existingUserData);
    };
  };
};
