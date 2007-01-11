// vim:syntax=lpc
#include <debug.h>

inherit PSYC.MethodMultiplexer;

PSYC.Handler.Base reply;// = PSYC.Handler.Reply();
PSYC.Handler.Base auth;// = PSYC.Handler.Auth();
object storage;

object server;
MMP.Uniform uni;
mapping(MMP.Uniform:int) counter = ([]);

mixed cast(string type) {
    if (type == "string") return sprintf("Unl(%s)", qName());
}

MMP.Uniform qName() {
    return uni;
}

void check_authentication(MMP.Uniform t, function cb, mixed ... args) {
    call_out(cb, 0, uni == t, @args);
}

PSYC.Packet tag(PSYC.Packet m, function|void callback, mixed ... args) {
    return tagv(m, callback, 0, @args);
}

PSYC.Packet tagv(PSYC.Packet m, function|void callback, multiset(string)|mapping wvars, 
		 mixed ... args) {
    m->vars["_tag"] = reply->make_reply(callback, wvars, @args);

    return m;
}

void create(MMP.Uniform u, object s, object stor) {
    PT(("PSYC.Unl", "created object for %s.\n", u))
    uni = u;
    server = s;
    storage = stor;
    ::create(stor);

    add_handlers(auth = PSYC.Handler.Auth(this, sendmmp, uni),
		 reply = PSYC.Handler.Reply(this, sendmmp, uni));
    // the order of storage and trustiness is somehow critical..
}

void sendmmp(MMP.Uniform t, MMP.Packet p) {
    P0(("PSYC.Unl", "%O->sendmmp(%O, %O)\n", this, t, p))
    
    if (!has_index(p->vars, "_context")) {
	if (!has_index(p->vars, "_target")) {
	    p["_target"] = t;
	}

	if (!has_index(p->vars, "_source")) {
	    p["_source"] = uni;
	}

	if (!has_index(p->vars, "_counter")) {
	    p["_counter"] = counter[p["_source"]]++;
	}
    }

    server->deliver(t, p);
}

