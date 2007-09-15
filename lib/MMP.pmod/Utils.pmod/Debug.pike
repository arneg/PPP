.DebugManager _debugmanager;

// so the backtrace won't get messed up
function debug;
function do_throw;

void create(.DebugManager s) {
    _debugmanager = s;

    debug = s->debug;
    do_throw = s->do_throw;
}
