// functions/inc.mo
import Storage "../storage"

module Inc {
  public func invoke(storage : Storage.Storage) {
    let current = storage.get();
    storage.set(current + 1);
  };
};
