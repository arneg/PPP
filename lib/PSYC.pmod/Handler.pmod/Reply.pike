#include <random.h>

inherit PSYC.Handler.Base;

constant _ = ([
    "filter" : ([
	"" : ([ ]),
    ]),
]);

mapping(string:array) reply = ([ ]);

int add_reply(function cb, string tag, mixed ... args) {
    if (has_index(reply, tag)) return 0;

    reply[tag] = ({ cb, args });
    return 1;
}

string make_reply(function cb, mixed ... args) {
    string tag;

    while (has_index(reply, tag = RANDHEXSTRING));
    add_reply(cb, tag, @args);
}

int filter(MMP.Packet p, mapping _v) {
    
    if (has_index(p->vars, "_tag_reply")) {
	if (has_index(reply, p->vars["_tag_reply"])) {
	    array(mixed) ca = m_delete(reply, p->vars["_tag_reply"]);
	    call_out(ca[0], 0, p, @(ca[1]));
	    return 0;
	} else {
	    // bad reply.. complain
	    return 0;
	}
    }

    return 1;
}


