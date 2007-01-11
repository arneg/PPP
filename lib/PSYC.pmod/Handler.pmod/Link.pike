// vim:syntax=lpc
#include <debug.h>

inherit PSYC.Handler.Base;

constant _ = ([
    "prefilter" : ([
	"" : 0,
    ]),
    "postfilter" : ([
	"_request_link" : ({ "_password" }),
	"_request_unlink" : 0,
	"_set_password" : ({ "_password" }),
    ]),
]);

int prefilter(MMP.Packet p, mapping _v, mapping _m) {
    
    if (parent->attached(p->source())) {
	_m["itsme"] = 1;
    } else {
	_m["itsme"] = 0;
    }

    return PSYC.Handler.GOON;
}

int postfilter_request_link(MMP.Packet p, mapping _v, mapping _m) {

    PSYC.Packet m = p->data;

    if (!has_index(m->vars, "_password")) {
	sendmsg(p["_source"], m->reply("_query_password"));
	return PSYC.Handler.STOP;
    }

    P3(("PSYC.Handler.Link", "comparing %O and %O.\n", _v["_password"], m->vars["_password"]))

    if (_v["_password"] == m->vars["_password"]) {
	parent->attach(p["_source"]);
	sendmsg(p["_source"], m->reply("_notice_link"));	
    } else {
	sendmsg(p["_source"], m->reply("_error_invalid_password"));
    }
    return PSYC.Handler.STOP;
}

int postfilter_set_password(MMP.Packet p, mapping _v, mapping _m) {
    return postfilter_request_link(p, _v, _m); 
}

int postfilter_request_unlink(MMP.Packet p, mapping _v, mapping _m) {

    parent->detach(p["_source"]);
    sendmsg(p["_source"], p->data->reply("_notice_unlink"));
    return PSYC.Handler.STOP;
}
