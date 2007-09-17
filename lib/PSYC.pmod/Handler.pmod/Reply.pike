// vim:syntax=lpc
#include <random.h>
#include <debug.h>
#include <assert.h>
#define CB	0
#define ARGS	1
#define WVARS	2
#define LVARS	3
#define ASYNC	4

inherit PSYC.Handler.Base;

constant _ = ([
    "filter" : ([
	"" : ([ "async" : 1 ]),
    ]),
]);

constant export = ({
    "add_reply", "make_reply", /*"send_tagged", "send_tagged_v"*/
});

mapping(string:array) reply = ([ ]);

int add_reply(function cb, string tag, multiset(string)|mapping vars, mixed ... args) {
    if (has_index(reply, tag)) return 0;
    multiset wvars, lvars;
    int async = 0;

    P2(("Handler.Reply", "%O: added tag(%s) with %O for %O.\n", parent, tag, vars, cb))

    if (multisetp(vars)) {
	wvars = vars;
    } else if (mappingp(vars)) {
	if (has_index(vars, "lock")) {
	    if (multisetp(vars["lock"])) {
		lvars = (multiset)vars["lock"];
	    } else {
		THROW(sprintf("set of locked variables has to be an array.\n"));
	    }
	}

	if (has_index(vars, "wvars")) {
	    if (multisetp(vars["wvars"])) {
		wvars = (multiset)vars["wvars"];
	    } else {
		THROW(sprintf("set of variables has to be an array.\n"));
	    }
	}
	async = has_index(vars, "async") && vars["async"];
    }

    reply[tag] = ({ cb, args, wvars, lvars, async });
    return 1;
}


string make_reply(function cb, multiset(string)|mapping vars, mixed ... args) {
    string tag;

    P2(("Handler.Reply", "%O: make_reply(%O, %O, %O)\n", this, cb, vars, args))

    while (has_index(reply, tag = RANDHEXSTRING));
    add_reply(cb, tag, vars, @args);
    return tag;
}

int filter(MMP.Packet p, mapping _v, mapping _m, function cb) {
    PSYC.Packet m = p->data;

    P3(("Handler.Reply", "%O: prefilter(%O)\n", parent, p))
    
    if (has_index(m->vars, "_tag_reply")) {
	string tag = m->vars["_tag_reply"];

	if (has_index(reply, tag)) {
	    array(mixed) ca = reply[tag];

	    P3(("Handler.Reply", "%O: ca: %O\n", parent, ca))
	    // callback for storage
	    void got_data(mapping _v, MMP.Packet p, function callback, int async, mixed args) {
		array temp;

		if (sizeof(_v)) {
		    temp = ({ p, _v });
		} else {
		    temp = ({ p });
		}

		if (!async) {
		    void _cb(mixed ... args) {
			cb(callback(@args));
		    };
		    call_out(_cb, 0, @temp, @args);
		} else {
		    call_out(callback, 0, @temp, cb, @args);
		}
	    };

	    void fail(mixed ... args) {
		P0(("PSYC.Handler.Reply", "fetching data failed for someone.. %O\n", args))
		// TODO: das alles toller
	    };
	    enforcer(functionp(ca[CB]), "oups.. \n");
	    enforcer(functionp(cb), "!!oups.. \n");
	    // still some vars missing/supposed to come from storage
	    PSYC.Storage.multifetch(parent->storage, ca[LVARS], ca[WVARS], got_data, fail, p, ca[CB], ca[ASYNC], ca[ARGS]);
	    m_delete(reply, tag);
	    return PSYC.Handler.STOP;
	} else {
	    P0(("Handler.Reply", "packet %O (%O) is tagged with an unknown tag.\n", p, m))
	    // Not to bad. the packet may goon
	}
    }

    call_out(cb, 0, PSYC.Handler.GOON);
    return PSYC.Handler.STOP;
}
