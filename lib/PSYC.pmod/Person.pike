// vim:syntax=lpc
#include <new_assert.h>

inherit PSYC.Unl;
multiset clients = (< >);
object user; // euqivalent to the _idea_ of "user.c" in psycmuve

//! An implementation of a minimal user to which clients can be linked.

//! @param uni
//! 	Uniform of the user.
//! @param server
//! 	A server object providing mmp message delivery.
//! @param storage
//! 	An instance of a @[PSYC.Storage] Storage subclass.
//! @seealso
//! 	@[PSYC.Storage.File], @[PSYC.Storage.Remote], @[PSYC.Storage.Dummy]
void create(mapping params) {
    ::create(params);

    mapping handler_params = params + ([ "parent" : this, "sendmmp" : sendmmp ]);

    add_handlers(
	PSYC.Handler.Relay(handler_params),
	PSYC.Handler.Forward(handler_params),
	PSYC.Handler.Link(handler_params),
	PSYC.Handler.Echo(handler_params),
	PSYC.Handler.Storage(handler_params),
	PSYC.Handler.Trustiness(handler_params),
	PSYC.Handler.Channel(handler_params),
	PSYC.Handler.Subscribe(handler_params),
    );
    add_handlers(
	PSYC.Handler.Friendship(handler_params),
	PSYC.Handler.ClientFriendship(handler_params),
    );
}

int(0..1) is_newbie = 0;

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

    if (isNewbie()) {

	void callback(int error, string key, mapping sub) {
	    if (error != PSYC.Storage.OK) {
		debug("storage", 0, "leave failed because of storage.\n");
		return;
	    }

	    debug(([ "newbie" : 2, "local_object_destruct" : 1, "local_object" : 2 ]),
		  "leaving all places(%O) because we are a newbie\n", sub);

	    foreach (sub;MMP.Uniform channel;) {
		MMP.Utils.invoke_later(this->leave, channel);
	    }
	};

	storage->get("places", callback);

	object context = server->get_context(uni);

	foreach (context->members;MMP.Uniform member;) {
	    MMP.Utils.invoke_later(this->channel_remove, uni, member);
	}
    }
}

int attached(MMP.Uniform unl) {
    return has_index(clients, unl);
}

void check_authentication(MMP.Uniform t, function cb, mixed ... args) {

    debug("auth", 3,"looking for %O in %O.\n", t, clients);

    if (has_index(clients, t)) {
	call_out(cb, 0, 1, @args);	
	return;
    }
    
    ::check_authentication(t, cb, @args);
}

int isNewbie(void|int(0..1) i) {
    if (zero_type(i)) {
	return is_newbie;
    } else {
	return is_newbie = i;
    }
} 

void distribute(MMP.Packet p) {
    debug("packet_flow", 5, "distribute(%O)\n", p);

    PSYC.Packet m = p->data;

    foreach(clients; MMP.Uniform target;) {
	MMP.Packet pt = MMP.Packet(m, ([
			    "_source_relay" : p->lsource(),
			    "_source" : uni,
	]));
	if (has_index(p->vars, "_context")) {
	    pt["_context"] = p["_context"];
	}
	pt["_target"] = target;

	sendmmp(target, pt);
    }
}

