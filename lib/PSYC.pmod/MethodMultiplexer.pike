// vim:syntax=lpc
#include <debug.h>

PSYC.StageHandler prefilter, filter, postfilter;

void stop(MMP.Packet p) {
    P3(("MethodMultiplexer", "stopped %O.\n", p))
}

void finish(MMP.Packet p) {
    P3(("MethodMultiplexer", "finished %O.\n", p))
}

void create(PSYC.Storage storage) {
    postfilter = PSYC.StageHandler("postfilter", finish, finish, throw, storage);
    filter = PSYC.StageHandler("filter", postfilter->handle, stop, throw, storage);
    prefilter = PSYC.StageHandler("prefilter", filter->handle, filter->handle, 
				  throw, storage);
}

void add_handlers(PSYC.Handler.Base ... handlers) { 
    foreach (handlers;; PSYC.Handler.Base handler) {
	mapping temp = handler->_;
	if (has_index(temp, "prefilter")) 
	foreach (temp["prefilter"]; string mc; mapping|array(string) wvars) {
	    prefilter->add(mc, handler, wvars);
	}

	if (has_index(temp, "filter")) 
	foreach (temp["filter"]; string mc; mapping|array(string) wvars) {
	    filter->add(mc, handler, wvars);
	}

	if (has_index(temp, "postfilter")) 
	foreach (temp["postfilter"]; string mc; mapping|array(string) wvars) {
	    postfilter->add(mc, handler, wvars);
	}
    }
}

void msg(MMP.Packet p) {
    PT(("MethodMultiplexer", "%O: msg(%O)\n", this, p))
    
    if (p->data) {
	if (stringp(p->data)) {
#ifdef LOVE_TELNET
	    p->data = PSYC.parse(p->data, p->newline);
#else
	    p->data = PSYC.parse(p->data);
#endif
	}
    } else {
	PT(("MethodMultiplexer", "%O: got packet without data. maybe state changes\n"))
	return;
    }

    prefilter->handle(p, ([]));
}
