int _upcnt;
int(0..1) _done;
mapping _res = ([ ]);
function _cb;

void create(function cb) {
    _cb = cb;
}

void done() {
    _done = 1;

    if (!_upcnt) {
	_cb(_res);
    }
}

function get_cb(mixed name, int|void one) {
    _upcnt++;

    void cb(mixed ... args) {
	if (one && sizeof(args) == 1) {
	    _res[name] = args[0];
	} else {
	    _res[name] = args;
	}

	if (!--_upcnt && _done) {
	    _cb(_res);
	}
    };

    return cb;
}
