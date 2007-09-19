// vim:syntax=lpc
#include <new_assert.h>

inherit MMP.Utils.Debug;

PSYC.StageHandler stage;
object storage;

void stop(MMP.Packet p) {
    debug("packet_flow", 6, "%O stopped in 'casted' stage.\n", p);
}

void finish(MMP.Packet p) {
    debug("packet_flow", 6, "%O finished in 'casted' stage.\n", p);
}

void create(mapping params) {
    object handling;

    ::create(params["debug"]);

    enforce(objectp(storage = params["storage"]));
    enforce(objectp(handling = params["handling"]));

    handling->register_handler("casted", this);

    stage = PSYC.StageHandler(params + ([
		    "prefix" : "casted",
		    "goon" : finish,
		    "finish" : finish,
		    "stop" : stop,
			       ]));
}

void add_casted(object handler, mapping events) {
    foreach (events; string mc; mapping|array(string) wvars) {
	stage->add(mc, handler, wvars);
    }
}

void casted(MMP.Packet p) {
    stage->handle(p, ([]));
}
