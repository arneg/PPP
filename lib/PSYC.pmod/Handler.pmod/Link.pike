// vim:syntax=lpc
#include <debug.h>

inherit PSYC.Handler.Base;

constant _ = ([
    "postfilter" : ([
	"_request_link" : ({ "_password" }),
	"_request_unlink" : 0,
	"_set_password" : ({ "_password" }),
    ]),
]);

int postfilter_request_link(MMP.Packet p, mapping _v) {

    PSYC.Packet m = p->data;

    if (!has_index(m->vars, "_password")) {
	uni->sendmsg(p["_source"], m->reply("_query_password"));
	return 0;
    }

    P3(("PSYC.Handler.Link", "comparing %O and %O.\n", _v["_password"], m->vars["_password"]))

    if (_v["_password"] == m->vars["_password"]) {
	uni->attach(p["_source"]);
	uni->sendmsg(p["_source"], m->reply("_notice_link"));	
    } else {
	uni->sendmsg(p["_source"], m->reply("_error_invalid_password"));
    }
    return 0;
}

int postfilter_set_password(MMP.Packet p, mapping _v) {
    postfilter_request_link(p, _v); 
}

int postfilter_request_unlink(MMP.Packet p, mapping _v) {

    uni->detach(p["_source"]);
    uni->sendmsg(p["_source"], p->data->reply("_notice_unlink"));
    return 0;
}
