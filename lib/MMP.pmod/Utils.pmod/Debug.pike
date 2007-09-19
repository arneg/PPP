.DebugManager _debugmanager;

// so the backtrace won't get messed up
function debug;
function do_throw;

void create(.DebugManager s) {
    if (!(_debugmanager = s)) {
	throw(({ "No DebugManager given.\n", backtrace() }));
    }

    debug = s->debug;
    do_throw = s->do_throw;
}
