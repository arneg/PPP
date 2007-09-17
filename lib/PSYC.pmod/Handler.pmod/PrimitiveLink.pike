// vim:syntax=lpc
#include <new_assert.h>

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

void create(mapping params) {
    ::create(params);

    enforce(MMP.is_uniform(primitive = params["client_uni"]));
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

    if (parent->link_to == p->source()) {
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
	debug("Person", 2, "%O unlinked from %O because of delivery_failure.", m["_location"], parent);
    }

    return PSYC.Handler.GOON;
}
