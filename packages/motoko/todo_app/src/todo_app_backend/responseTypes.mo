module {
  public type GetByTaskIdResponseType = {
    id : Text;
    content : Text;
    status : Text;
    createdAt : Int;
    updatedAt : Int;
  };

  public type GetByUserIdResponseType = {
    userId : Text;
    data : [GetByTaskIdResponseType];
  };
};
