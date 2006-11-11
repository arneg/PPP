#include <random.h>
#include <debug.h>
#define CB	0
#define ARGS	1
#define WVARS	2
#define VARS	3
#define PACKET	4

inherit PSYC.Handler.Base;

constant _ = ([
    "filter" : ([
	"" : ([ ]),
    ]),
]);

mapping(string:array) reply = ([ ]);

int add_reply(function cb, string tag, multiset(string) vars, mixed ... args) {
    if (has_index(reply, tag)) return 0;

    PT(("Handler.Reply", "%O: added tag(%s) with %O for %O.\n", uni, tag, vars, cb))

    reply[tag] = ({ cb, args, vars, vars ? ([]) : 0 });
    return 1;
}


string make_reply(function cb, multiset(string) vars, mixed ... args) {
    string tag;

    PT(("Handler.Reply", "%O: make_reply(%O, %O, %O)\n", this, cb, vars, args))

    while (has_index(reply, tag = RANDHEXSTRING));
    add_reply(cb, tag, vars, @args);
    return tag;
}

int filter(MMP.Packet p, mapping _v, mapping _m) {
    PSYC.Packet m = p->data;

    P3(("Handler.Reply", "%O: prefilter(%O)\n", uni, p))
    
    if (has_index(m->vars, "_tag_reply")) {
	string tag = m->vars["_tag_reply"];

	if (has_index(reply, tag)) {
	    array(mixed) ca = reply[tag];

	    P3(("Handler.Reply", "%O: ca: %O\n", uni, ca))
	    // still some vars missing/supposed to come from storage
	    if (ca[WVARS] && sizeof(ca[WVARS])) {

		// requesting the data in got_data is _bad_ because a reply
		// should in theory take much longer than a storage request
		foreach(ca[WVARS]; string key;) {
		    uni->storage->get(key, got_data, tag);
		}
		ca += ({ p });
		return PSYC.Handler.STOP;
	    }

	    m_delete(reply, tag);
	    call_out(ca[CB], 0, p, @(ca[ARGS]));
	    return PSYC.Handler.STOP;
	} else {
	    // bad reply.. complain
	    return PSYC.Handler.STOP;
	}
    }

    return PSYC.Handler.GOON;
}

// callback for storage
void got_data(string key, mixed value, string tag) {
    
    if (has_index(reply, tag)) {
	array(mixed) ca = reply[tag];

	if (ca[WVARS] && has_index(ca[WVARS], key)) {
	    while(ca[WVARS]--);
	    
	    ca[VARS][key] = value;
	} else {
	    P0(("Handler.Reply", "%O: Got data (%s) for a reply to (%s) we never should have requested.\n", uni, key, tag))
	    return;
	}

	if (!sizeof(ca[WVARS])) { // done
	    m_delete(reply, tag);
	    call_out(ca[CB], 0, ca[PACKET], ca[VARS], @(ca[ARGS]));
	}

	return;
    }
	
    P0(("Handler.Reply", "%O: Got data (%s) from storage for an unknown reply to (%s).\n", uni, key, tag))
}
