// vim:syntax=lpc
#include <debug.h>

inherit PSYC.MethodMultiplexer;

PSYC.Handler.Base reply;// = PSYC.Handler.Reply();
PSYC.Handler.Base auth;// = PSYC.Handler.Auth();

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

PSYC.Packet tagv(PSYC.Packet m, function|void callback, multiset(string) wvars, 
		 mixed ... args) {
    m->vars["_tag"] = reply->make_reply(callback, wvars, @args);

    return m;
}

string send_tagged_v(MMP.Uniform target, PSYC.Packet m, multiset(string) wvars,
		     function callback, mixed ... args) {
    tagv(m, callback, wvars, @args); 
    call_out(sendmsg, 0, target, m);
    return m["_tag"];
}

string send_tagged(MMP.Uniform target, PSYC.Packet m, 
		   function callback, mixed ... args) {
    return send_tagged_v(target, m, 0, callback, @args);
}

void create(MMP.Uniform u, object s, object storage) {
    uni = u;
    server = s;
    ::create(storage);
    add_handlers(auth = PSYC.Handler.Auth(this),
		 reply = PSYC.Handler.Reply(this), 
		 PSYC.Handler.Storage(this, storage));
    // the order of storage and trustiness is somehow critical..
}

void sendmsg(MMP.Uniform target, PSYC.Packet m) {
    P3(("PSYC.Unl", "sendmsg(%O, %O)\n", target, m))
    MMP.Packet p = MMP.Packet(m, 
			  ([ "_source" : uni,
			     "_target" : target ]));
    sendmmp(target, p);    
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

