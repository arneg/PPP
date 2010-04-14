int _upcnt;
int(0..1) _done, _disabled;
mapping _res = ([ ]);
function _cb;

void create(function cb) {
    _cb = cb;
}

void done() {
    _done = 1;

    if (!_upcnt) {
	if (!_disabled) {
	    if (sizeof(_res)) {
		_cb(_res);
	    } else {
		_cb();
	    }
	}
	destruct(this);
    }
}

void disable() {
    _disabled = 1;
}

function get_cb(mixed|void name, int|void one) {
    _upcnt++;

    void cb(mixed ... args) {
	if (name || !zero_type(name)) {
	    if (one && sizeof(args) == 1) {
		_res[name] = args[0];
	    } else {
		_res[name] = args;
	    }
	}

	if (!--_upcnt && _done) {
	    if (!_disabled) {
		if (sizeof(_res)) {
		    _cb(_res);
		} else {
		    _cb();
		}
	    }
	    destruct(this);
	}
    };

    return cb;
}
