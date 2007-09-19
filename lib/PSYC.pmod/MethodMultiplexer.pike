// vim:syntax=lpc

#include <new_assert.h>

//! This class provides an amazingly sweet PSYC processing framework.
//! PSYC functionality can be added to an entity by
//! adding Handlers using @[add_handlers()].
//! @note
//! 	This class is designed for being inherited by PSYC entities.
//!	@[PSYC.Unl] already does that for you. Should you want to use it 
//!	differenly, remember to pass on incoming @[MMP.Packet]s to the @[msg()] 
//!	function.
//!
//! 	Better have a look at the source code, if you intend to use it without
//!	using @[PSYC.Unl]. @b{WE MEAN IT!@}.

inherit MMP.Utils.Debug;

PSYC.StageHandler stage_prefilter, stage_filter, stage_postfilter, stage_display;
object storage;

void stop(MMP.Packet p) {
    debug("packet_flow", 3, "stopped %O.\n", p);
}

void finish(MMP.Packet p) {
    debug("packet_flow", 3, "finished %O.\n", p);
}

#ifdef DEBUG
void throw(mixed ... x) {
    predef::throw(@x);
}
#endif

void create(mapping params) {
    // display is sortof isolated from the rest.. 
    //
    // we should think about introducing a different api.. one closure which gets called
    // with the returntype.. (for STOP and DISPLAY). 
    object handling;
    ::create(params["debug"]);
    enforce(objectp(handling = params["handling"]));
    enforce(objectp(storage = params["storage"]));
    handling->register_handler("display", this);
    handling->register_handler("postfilter", this);
    handling->register_handler("filter", this);
    handling->register_handler("prefilter", this);
    handling->register_handler("init", this);

    // >>>TODO>>> change mapping keys from "goon" to the corresponding
    // constants. that way enabling MORE pwnage. <<<TODO<<<
    //
    // TODO, TOO: write an auto_unfpld macro for vim, unfplding mappings.
    //
    // TODO: start writing more TODOs at places where you will NEVER see them again.
    //
    // TODO: alias ft grep -rn TODO *

    stage_display = PSYC.StageHandler(params + ([
					   "prefix" : "display",
					   "goon" : finish,
					   "stop" : stop,
					   "display" : finish,
					   "error" : do_throw
					   ]));
    stage_postfilter = PSYC.StageHandler(params + ([
					  "prefix" : "postfilter",
					  "goon" : stage_display->handle,
					  "stop" : stop,
					  "display" : stage_display->handle,
					  "error" : do_throw
				  	 ]));
    stage_filter = PSYC.StageHandler(params + ([
					 "prefix" : "filter",
					 "goon" : stage_postfilter->handle,
					 "stop" : stop,
					 "display" : stage_display->handle,
					 "error" : do_throw
				      ]));
    stage_prefilter = PSYC.StageHandler(params + ([
					    "prefix" : "prefilter",
					    "goon" : stage_filter->handle,
					    "stop" : stage_filter->handle,
					    "display" : stage_filter->handle,
					    "error" : do_throw
				  ]));
    // packet handling chain goes here. We could make it more general by supplying a mapping of
    // return values to functions.
}

#define ADD(x)	void add_##x(object handler, mapping events) { \
    foreach (events; string mc; mapping|array(string) wvars) { \
	stage_##x->add(mc, handler, wvars); \
    } \
}

ADD(postfilter)
ADD(filter)
ADD(prefilter)
ADD(display)

#undef ADD

#define HANDLE(x)	void  x (MMP.Packet p, mapping _m) {\
    stage_##x->handle(p, _m);\
}
#define DONT_HANDLE(x)	void  x (MMP.Packet p, mapping _m) {\
    debug("event_handling", 0, "I do not handle manual ##x events.\n");\
}

HANDLE(prefilter)
HANDLE(display)
DONT_HANDLE(postfilter)
DONT_HANDLE(filter)

#undef HANDLE
#undef DONT_HANDLE

void add_init(object handler, mixed cred) {
    call_init(handler, PSYC.handler_parser(cred));
}
void call_init(object handler, PSYC.AR o) {
    debug("handler_management", 3, "Calling %O for init.\n", o->handler);
    PSYC.Storage.multifetch(this->storage, o->lvars && (multiset)o->lvars, o->wvars && (multiset)o->wvars, 
			    handler->init,0); 
}

// maybe we should actually call init with the handler as the argument.
void init() {
    // dummy.. we need to change that
}

