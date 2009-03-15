constant OK 		= 0;
constant LOCKED 	= 1;
constant UNSUPPORTED 	= 2;

class ApplyInfo {
    int changed = 0;
    int depth = 0;
    int faildepth = 0;
    int failed = 0;
    int ret = 0;
    int locked_above = 0;
    array(Serialization.Atom) path = ({});
    object lock;
    object state() {
	if (sizeof(path)) {
	    return path[sizeof(path)-1];
	}
	return 0;
    }

    string _sprintf(int type) {
	return sprintf("ApplyInfo(%O)\n", mkmapping(indices(this), values(this)) - ({ "_sprintf", "state" }));
    }
}
