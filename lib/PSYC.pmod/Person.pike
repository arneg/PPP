// vim:syntax=lpc
#include <debug.h>

//! An implementation of a minimal user to which clients can be linked.

inherit PSYC.Unl;
multiset clients = (< >);
object user; // euqivalent to the _idea_ of "user.c" in psycmuve
PSYC.Handler.Base relay;
PSYC.Handler.Base link;
PSYC.Handler.Base forward;
PSYC.Handler.Base echo;

string _sprintf(int type) {
    return sprintf("Person(%O)", uni);
}

void attach(MMP.Uniform unl) {
    clients[unl] = 1;

    this->castmsg(uni, PSYC.Packet("_notice_presence_here"));
}

void detach(MMP.Uniform unl) {
    //client -= (< unl >);
    clients[unl] = 0;

    this->castmsg(uni, PSYC.Packet("_notice_presence_absent"));
}

int attached(MMP.Uniform unl) {
    return has_index(clients, unl);
}

void check_authentication(MMP.Uniform t, function cb, mixed ... args) {

    P3(("PSYC.Person", "looking for %O in %O.\n", t, clients))

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
    P3(("Person", "distribute(%O)\n", p))

    PSYC.Packet m = p->data;

    foreach(clients; MMP.Uniform target;) {
	MMP.Packet pt = MMP.Packet(m, ([
			    "_source_relay" : p->lsource(),
			    "_source" : uni,
	]));
	if (has_index(p->vars, "_context")) {
	    pt["_context"] = p["_context"];
	}
		
	sendmmp(target, pt);
    }
}

//! @param uni
//! 	Uniform of the user.
//! @param server
//! 	A server object providing mmp message delivery.
//! @param storage
//! 	An instance of a @[PSYC.Storage] Storage subclass.
//! @seealso
//! 	@[PSYC.Storage.File], @[PSYC.Storage.Remote], @[PSYC.Storage.Dummy]
void create(MMP.Uniform uni, object server, object storage) {
    ::create(uni, server, storage);

    forward = PSYC.Handler.Forward(this, sendmmp, uni);
    relay = PSYC.Handler.Relay(this, sendmmp, uni);
    link = PSYC.Handler.Link(this, sendmmp, uni);
    echo = PSYC.Handler.Echo(this, sendmmp, uni);
    add_handlers(
		 relay, link, forward, echo, 
		 PSYC.Handler.Storage(this, sendmmp, uni, storage),
		 PSYC.Handler.Trustiness(this, sendmmp, uni),
		 PSYC.Handler.Channel(this, sendmmp, uni),
		 PSYC.Handler.Subscribe(this, sendmmp, uni),
		 );
    add_handlers(
		 PSYC.Handler.Friendship(this, sendmmp, uni),
		 );
}

