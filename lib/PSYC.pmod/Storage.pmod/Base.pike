// this could be used by others
void multi_apply(array(array) list, function callback, mixed ... args) {
    int num = sizeof(list);
    int failed = 0;
    array(array) ret = allocate(sizeof(list));
    
    void cb(int err, object misc, int id) {
	ret[id] = ({ err, misc });

	if (!(--num)) {
	    MMP.Utils.invoke_later(callback, ret, @args);
	}
    };

    foreach (list;int i;array a) {
	// we want to use even overloaded stuff
	this->apply(a[0], a[1], cb, i);
    }
}
