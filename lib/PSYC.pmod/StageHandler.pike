// vim:syntax=lpc
#include <new_assert.h>

// TODO
// - let the check function return variables to request.

inherit MMP.Utils.Debug;

object storage;
mapping table = ([]);
mapping requested = ([]);
function goon, stop, error, display;
string prefix;

void create(mapping params) {

    ::create(params["debug"]);
    prefix = params["prefix"];

    enforce(callablep(goon = params["goon"]));
    enforce(callablep(stop = params["stop"]));
    error = params["error"];
    display = params["display"];

    enforce(objectp(storage = params["storage"]));
}

#ifdef DEBUG
string _sprintf(int type) {
    if (type == 'O') {
	return sprintf("StageHandler(%O)", function_object(error));
    }
}
#endif


void add(string mc, object handler, void|mapping|array(string) d) {
    PSYC.AR result;

    debug("handler_management", 3, "%O->add(%O, %O)\n", prefix, mc, handler);
    if (!has_index(table, mc)) table[mc] = ({ }); 

    result = PSYC.handler_parser(d);

    result->handler = `->(handler, prefix + mc);
    enforcer(functionp(result->handler),
	     sprintf("No method %s defined in %O.\n", prefix+mc, handler));

    if (result->check) {
	result->check = `->(handler, result->check);
	enforcer(functionp(result->check),
		 sprintf("No method %s is defined in %O.\n", d["check"], handler));
    }
    table[mc] += ({ result });

}

void handle(MMP.Packet p, mapping _m) {

    debug("packet_flow", 3, "%s:handle(%s)\n", prefix, p->data->mc);

    array(string) l = p->data->mc / "_";
    MMP.Utils.Queue liste = MMP.Utils.Queue(); 

    for (int i = sizeof(l)-1; i >= 0; i--) {
	string temp = l[0..i] * "_";
	if (has_index(table, temp)) {
	    foreach(table[temp];; object a) {
		liste->push(a);
	    }
	}
    }

#if DEBUG > 1
    if (!sizeof(liste)) {
	debug(([ "packet_flow" : 1, "handler" : 2 ]), "%O: no stack for method %s.\n", prefix, p->data->mc);
    } else {
	debug(([ "packet_flow" : 3, "handler" : 4 ]), "%O: stack for %s is %O\n", prefix, p->data->mc, (array)liste);
    }
#endif
    progress(liste, p, _m);
}

void progress(MMP.Utils.Queue stack, MMP.Packet p, mapping _m) {
    debug("packet_flow", 3, "%O: progressing %O.\n", prefix, stack);

    if (stack->isEmpty()) {
	call_out(goon, 0, p, _m);

	return;
    }
    
    PSYC.AR o = stack->shift_();

    if (o->check && !o->check(p, _m)) {
	debug("packet_flow", 2, "%O: %O->check() returned Null.\n", prefix, o);
	stack->shift();
	call_out(progress, 0, stack, p, _m);
	return;
    }

    void fail(MMP.Utils.Queue stack, MMP.Packet p, mapping _m) {
	debug("storage", 0, "fetching data for %O failed in stack %O.\n", p, stack);
    };

    array(mixed) args = ({ storage, o->lvars && (multiset)o->lvars, o->wvars && (multiset)o->wvars, call_handler, fail, stack, p, _m });

    // we have to check prior to fetching!!! otherwise we will fetch broken stuff prior to initialization.
    // alternative: lock init vars.. ,)
    // better: do both
    if (has_index(function_object(o->handler)->_, "_")) {
	object handler = function_object(o->handler);

	if (!handler->is_inited()) {
	    debug("handler_init", -1, "%O not inited yet. queueing %O.\n", handler, p->data);
	    handler->init_cb_add(PSYC.Storage.multifetch, @args);
	    return;
	}
    }

    PSYC.Storage.multifetch(@args);

}

#if 0
    array wvars = o->wvars;
    array lvars = o->lvars;

    if (wvars || lvars) {
	multiset rvars;
	if (wvars && lvars) {
	    rvars = (multiset)wvars;
	    rvars += (multiset)lvars;
	} else {
	    rvars = (multiset)(wvars || lvars);
	}

	requested[p] = ([ ]);

	if (wvars) foreach(wvars;; string key) {
	    storage->get(key, fetched, stack, p, _m, rvars);
	}

	if (lvars) foreach(lvars;; string key) {
	    storage->get_lock(key, fetched, stack, p, _m, rvars);
	}

    } else {
	call_out(call_handler, 0, stack, p, ([]), _m);	
    }
#endif

void call_handler(mapping _v, MMP.Utils.Queue stack, MMP.Packet p, mapping _m) {
    PSYC.AR o = stack->shift();
    debug("packet_flow", 3, "Calling %O for %O with misc: %O.\n", o->handler, p, _m);


    int in_progress = 1;
    
    if (o->async) {
	void callback(int i) {
	    if (in_progress) {
		throw(({ "callback called, but handler didn't yet return. "
			 "use call_out, stupid!", backtrace() }));
	    }

	    // copied code comes here.
	    switch (i) {
	    case PSYC.Handler.GOON:
		progress(stack, p, _m);
		break;
	    case PSYC.Handler.STOP:
		stop(p, _m);
		break;
	    case PSYC.Handler.DISPLAY:
		if (display) display(p, _m);
		break;
	    default:
		do_throw("warning", "Illegal return type from Handler function %O.\n", o->handler);
	    }
	};

	debug("packet_flow", 3, "attempting to call %O.\n", o->handler);

	o->handler(p, _v, _m, callback);
	in_progress = 0;
    } else {
	int ret = o->handler(p, _v, _m);
	switch (ret) {
	case PSYC.Handler.GOON:
	    progress(stack, p, _m);
	    break;
	case PSYC.Handler.STOP:
	    stop(p, _m);
	    break;
	case PSYC.Handler.DISPLAY:
	    if (display) display(p, _m);
	    break;
	default:
	    do_throw("warning", "Illegal return type from Handler function %O.\n", o->handler);
	}
    }

}
