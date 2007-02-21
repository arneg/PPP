// vim:syntax=lpc
#include <random.h>
#include <debug.h>
#define CB	0
#define ARGS	1
#define WVARS	2
#define LVARS	3

inherit PSYC.Handler.Base;

constant _ = ([
    "filter" : ([
	"" : ([ ]),
    ]),
]);

constant export = ({
    "add_reply", "make_reply"
});

mapping(string:array) reply = ([ ]);

int add_reply(function cb, string tag, multiset(string)|mapping vars, mixed ... args) {
    if (has_index(reply, tag)) return 0;
    multiset wvars, lvars;

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
    }

    reply[tag] = ({ cb, args, wvars, lvars });
    return 1;
}


string make_reply(function cb, multiset(string)|mapping vars, mixed ... args) {
    string tag;

    P2(("Handler.Reply", "%O: make_reply(%O, %O, %O)\n", this, cb, vars, args))

    while (has_index(reply, tag = RANDHEXSTRING));
    add_reply(cb, tag, vars, @args);
    return tag;
}

int filter(MMP.Packet p, mapping _v, mapping _m) {
    PSYC.Packet m = p->data;

    P3(("Handler.Reply", "%O: prefilter(%O)\n", parent, p))
    
    if (has_index(m->vars, "_tag_reply")) {
	string tag = m->vars["_tag_reply"];

	if (has_index(reply, tag)) {
	    array(mixed) ca = reply[tag];

	    P3(("Handler.Reply", "%O: ca: %O\n", parent, ca))
	    // callback for storage
	    void got_data(mapping _v, MMP.Packet, function callback, mixed args) {
		if (sizeof(_v)) {
		    call_out(callback, 0, p, _v, @args); 
		} else {
		    call_out(callback, 0, p, @args); 
		}
	    };

	    void fail(MMP.Packet, function callback, mixed args) {
		P0(("PSYC.Handler.Reply", "fetching data failed for someone.. %O\n", args))
		// TODO: das alles toller
	    };
	    // still some vars missing/supposed to come from storage
	    PSYC.Storage.multifetch(parent->storage, ca[LVARS], ca[WVARS], got_data, fail, p, ca[CB], ca[ARGS]);
	    m_delete(reply, tag);
	    return PSYC.Handler.STOP;
	} else {
	    P0(("Handler.Reply", "packet %O is tagged with an unknown tag.", p))
	    // bad reply.. complain
	    return PSYC.Handler.GOON;
	}
    }

    return PSYC.Handler.GOON;
}

