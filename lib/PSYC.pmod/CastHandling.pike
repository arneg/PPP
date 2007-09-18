// vim:syntax=lpc
#include <debug.h>

PSYC.StageHandler stage;
object storage;

void stop(MMP.Packet p) {
    P3(("MethodMultiplexer", "stopped %O.\n", p))
}

void finish(MMP.Packet p) {
    P3(("MethodMultiplexer", "finished %O.\n", p))
}

void create(object handling, object _storage) {
    storage = _storage;

    handling->register_handler("casted", this);

    stage = PSYC.StageHandler("casted", finish, stop, finish, throw, storage);
}

void add_casted(object handler, mapping events) {
    foreach (events; string mc; mapping|array(string) wvars) {
	stage->add(mc, handler, wvars);
    }
}

void casted(MMP.Packet p) {
    stage->handle(p, ([]));
}
