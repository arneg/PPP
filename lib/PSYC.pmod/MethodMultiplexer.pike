// vim:syntax=lpc
#include <debug.h>

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

PSYC.StageHandler stage_prefilter, stage_filter, stage_postfilter, stage_display;
object storage;

void stop(MMP.Packet p) {
    P3(("MethodMultiplexer", "stopped %O.\n", p))
}

void finish(MMP.Packet p) {
    P3(("MethodMultiplexer", "finished %O.\n", p))
}

#ifdef DEBUG
void throw(mixed ... x) {
    predef::throw(@x);
}
#endif

void create(object handling, object _storage) {
    storage = _storage;
    // display is sortof isolated from the rest.. 
    //
    // we should think about introducing a different api.. one closure which gets called
    // with the returntype.. (for STOP and DISPLAY). 
    handling->register_handler("display", this);
    handling->register_handler("postfilter", this);
    handling->register_handler("filter", this);
    handling->register_handler("prefilter", this);
    handling->register_handler("init", this);

    // packet handling chain goes here. We could make it more general by supplying a mapping of
    // return values to functions.
    stage_display = PSYC.StageHandler("display", finish, stop, finish, throw, storage);
    stage_postfilter = PSYC.StageHandler("postfilter", stage_display->handle, stop, stage_display->handle, throw, storage);
    stage_filter = PSYC.StageHandler("filter", stage_postfilter->handle, stop, stage_display->handle, throw, storage);
    stage_prefilter = PSYC.StageHandler("prefilter", stage_filter->handle, stage_filter->handle, stage_filter->handle, throw, storage);
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
    P0(("MethodMultiplexer", "I do not handle manual ##x events.\n"))\
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
    P3(("StageHandler", "Calling %O for init.\n", o->handler))
    PSYC.Storage.multifetch(this->storage, o->lvars && (multiset)o->lvars, o->wvars && (multiset)o->wvars, 
			    handler->init,0); 
}

// maybe we should actually call init with the handler as the argument.
void init() {
    P0(("Multiplexer", "Init happens only once.. \n"))
}

