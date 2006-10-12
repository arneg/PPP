// vim:syntax=lpc
#include <debug.h>

inherit PSYC.Unl;
multiset clients = (< >);
object user; // euqivalent to the _idea_ of "user.c" in psycmuve
PSYC.Handler.Base relay;
PSYC.Handler.Base link;
PSYC.Handler.Base forward;

// wie waren diese unterschiedlichen level? fippo hatte doch das alles
// sich genau überlegt.
// friends landet dann ja wohl im v..
mixed v;

void attach(MMP.Uniform unl) {
    clients[unl] = 1;
}

void detach(MMP.Uniform unl) {
    //client -= (< unl >);
    clients[unl] = 0;
}

void check_authentication(MMP.Uniform t, function cb, mixed ... args) {

    PT(("PSYC.Person", "looking for %O in %O.\n", t, clients))

    if (has_index(clients, t)) {
	call_out(cb, 0, 1, @args);	
	return;
    }
    
    ::check_authentication(t, cb, @args);
}

int isNewbie() {
    return 0;
}

void distribute(MMP.Packet p) {

    PSYC.Packet m = p->data;

    foreach(clients; MMP.Uniform target;) {
	sendmmp(target, MMP.Packet(m, ([
			    "_source_relay" : p->lsource,
			    "_source" : uni,
				       ])));
    }
}

// vielleicht ist das nicht gut
void create(string nick, MMP.Uniform uni, object server) {
    ::create(uni, server, PSYC.DummyStorage());

    forward = PSYC.Handler.Forward(this);
    relay = PSYC.Handler.Relay(this);
    link = PSYC.Handler.Link(this);
    add_handlers(relay, link, forward);
}

