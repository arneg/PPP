// vim:syntax=lpc

PSYC.StageHandler prefilter, filter, postfilter;

void stop(MMP.Packet p) {
    P(("stopped %O.\n", p))
}

void finish(MMP.Packet p) {
    P(("finished %O.\n", p))
}

void create(PSYC.Storage storage) {
    postfilter = PSYC.StageHandler("postfilter", finish, finish, throw);
    filter = PSYC.StageHandler("filter", postfilter->handle, stop, throw);
    prefilter = PSYC.StageHandler("prefilter", filter->handle, filter->handle, 
				  throw);
}

void add_handlers(PSYC.Handler ... handlers) { 
    foreach (handlers;; PSYC.Handler handler) {
	foreach (handler->prefilter; string mc; array(string) wvars) {
	    prefilter->add(mc, handler, wvars);
	}

	foreach (handler->filter; string mc; array(string) wvars) {
	    filter->add(mc, handler, wvars);
	}

	foreach (handler->postfilter; string mc; array(string) wvars) {
	    postfilter->add(mc, handler, wvars);
	}
    }
}

void msg(MMP.Packet p) {
    prefilter->handle(p);
}
