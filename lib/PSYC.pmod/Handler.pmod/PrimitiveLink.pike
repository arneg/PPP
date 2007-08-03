// vim:syntax=lpc
#include <debug.h>

inherit PSYC.Handler.Base;
MMP.Uniform primitive; 

constant _ = ([
    "prefilter" : ([
	"" : 0,
    ]),
    "postfilter" : ([
	"_failure_delivery" : 0,
	"_notice_link" : 0,
    ]),
]);

void create(object o, function fun, MMP.Uniform uni, MMP.Uniform client_uni) {
    primitive = client_uni;
    ::create(o, fun, uni);
    call_out(parent->authenticate, 0, primitive);
}

int prefilter(MMP.Packet p, mapping _v, mapping _m) {

    MMP.Uniform s = p["_source"]; // source() is safe only after filter stage
    MMP.Uniform ls = p["_source_relay"] || s;
    
    if ((parent->link_to == s && ls == primitive) || 
	s == primitive) {
	_m["itsme"] = 1;
    } else {
	_m["itsme"] = 0;
    }

    return PSYC.Handler.GOON;
}

int postfilter_notice_link(MMP.Packet p, mapping _v, mapping _m) {
    PT(("Handler.PrimitiveLink", "_notice_link!!!\n"));

    if (parent->link_to == p->source()) {
	PT(("Handler.PrimitiveLink", "lets auth!\n"));
	sendmsg(p->source(), PSYC.Packet("_request_authenticate", ([ "_location" : primitive ])));
    }

    return PSYC.Handler.GOON;
}

int postfilter_failure_delivery(MMP.Packet p, mapping _v, mapping _m) {
    PSYC.Packet m = p->data;

    if (MMP.is_uniform(m["_location"]) && m["_location"] == primitive) {
	parent->detach(m["_location"]);
	parent->client->unlink();
	destruct(parent);
	P1(("Person", "%O unlinked from %O because of delivery_failure.", m["_location"], parent))
    }

    return PSYC.Handler.GOON;
}
