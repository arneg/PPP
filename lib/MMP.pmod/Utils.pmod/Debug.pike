DebugManager server;

void create(DebugManager s) {
    server = s;
}

// so the backtrace won't get messed up
function debug = server->debug;
function do_throw = server->do_throw;
