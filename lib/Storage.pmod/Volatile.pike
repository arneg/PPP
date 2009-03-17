Serialization.Atom storage;

void apply(object signature, Serialization.Atom query, function callback, mixed ... args) {

    object misc = Serialization.Types.ApplyInfo();
    int ret = signature->apply(query, storage, misc);

    if (ret == Serialization.Types.OK) {
	MMP.Utils.invoke_later(callback, ret, misc, @args);
    } else if (ret == Serialization.Types.LOCKED) {
	// keep the query
	misc->lock->on_unlock(apply, signature, query, callback, @args);
    } else if (ret == Serialization.Types.UNSUPPORTED) {
	MMP.Utils.invoke_later(callback, ret, misc, @args);
    }
}
