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

PSYC.StageHandler prefilter, filter, postfilter, display;
mapping(string:function) exports = ([]);

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

void create(object storage) {
    // display is sortof isolated from the rest.. 
    //
    // we should think about introducing a different api.. one closure which gets called
    // with the returntype.. (for STOP and DISPLAY). 
    display = PSYC.StageHandler("display", finish, stop, finish, throw, storage);
    postfilter = PSYC.StageHandler("postfilter", display->handle, stop, display->handle, throw, storage);
    filter = PSYC.StageHandler("filter", postfilter->handle, stop, display->handle, throw, storage);
    prefilter = PSYC.StageHandler("prefilter", filter->handle, filter->handle, filter->handle, throw, storage);
}


//! Add handlers.
void add_handlers(PSYC.Handler.Base ... handlers) { 
    P2(("MethodMultiplexer", "add_handler(%O) in %O\n", handlers, this))
    foreach (handlers;; PSYC.Handler.Base handler) {
	mapping temp = handler->_;

	if (has_index(temp, "_")) {
	    call_init(handler, PSYC.handler_parser(temp["_"]));
	}

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

	if (has_index(temp, "display")) 
	foreach (temp["display"]; string mc; mapping|array(string) wvars) {
	    display->add(mc, handler, wvars);
	}
    }

    do_import(@handlers);
}

mixed `->(string fun) {
    if (has_index(exports, fun)) {
	return exports[fun];
    }
        
    // TODO: change this when pike 7.7 is there.
    // 	     this is a hack.
    if (has_index(this, fun)) {
	return this[fun];
    }
    return UNDEFINED;
}

void call_init(object handler, PSYC.AR o) {
    P3(("StageHandler", "Calling %O for init.\n", o->handler))
    PSYC.Storage.multifetch(this->storage, o->lvars && (multiset)o->lvars, o->wvars && (multiset)o->wvars, 
			    handler->init,0); 
}

void do_import(PSYC.Handler.Base ... handlers) {
    foreach (handlers;; PSYC.Handler.Base handler) {
	if (has_index(handler, "export")) {
	    foreach (handler->export;;string fun) {
		exports[fun] = predef::`->(handler, fun);
	    }
	}
    }
}

//! Entry point for processing PSYC messages through this handler framework.
//! @param p
//! 	An @[MMP.Packet] containing parseable PSYC as a string or @[PSYC.Packet].
//!
//! 	This will do everything from throwing to nothing if you provide something else.
void msg(MMP.Packet p) {
    P3(("MethodMultiplexer", "%O: msg(%O)\n", this, p))
    
    object factory() {
	return JSON.UniformBuilder(this->server->get_uniform);
    };

    mixed parse_JSON(string d) {
	return JSON.parse(d, 0, 0, ([ '\'' : factory ]));
    };
    
    if (p->data) {
	if (stringp(p->data)) {
#ifdef LOVE_TELNET
	    p->data = PSYC.parse(p->data, parse_JSON, p->newline);
#else
	    p->data = PSYC.parse(p->data, parse_JSON);
#endif
	}
    } else {
	P1(("MethodMultiplexer", "%O: got packet without data. maybe state changes\n"))
	return;
    }

    prefilter->handle(p, ([]));
}
