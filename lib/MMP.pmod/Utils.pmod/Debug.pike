DebugManager server;

void create(DebugManager s) {
    server = s;
}

void debug(mixed ... args) {
    server->debug(@args);
}

// so the backtrace won't get messed up
function do_throw = server->do_throw;
