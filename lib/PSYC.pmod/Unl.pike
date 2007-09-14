// vim:syntax=lpc
#include <debug.h>

//! The simplest PSYC speaking object in whole @i{PSYCSPACE@}. Does
//! Remote Authentication and Reply using uthe 

inherit PSYC.Handling;

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

//! @param u
//! 	The @[MMP.Uniform] of the new entity.
//! @param s
//! 	The @[PSYC.Server] this entity shall live in.
//! @param stor
//! 	An instance of a @[PSYC.Storage] Storage subclass.
//! @seealso
//! 	@[PSYC.Storage.File], @[PSYC.Storage.Remote], @[PSYC.Storage.Dummy]
//! @note
//!	PSYC entities should not be created anytime anywhere, but by the
//! 	callbacks to the @[PSYC.Server] that will get called if someone
//! 	tries to reach a non-present entity.
void create(MMP.Uniform u, object s, object stor) {
    P2(("PSYC.Unl", "created object for %s.\n", u))
    uni = u;
    server = s;
    storage = stor;

    PSYC.MethodMultiplexer(this, storage);
    PSYC.NotifyHandling(this, storage);
    PSYC.CheckHandling(this, storage);
    // the order of storage and trustiness is somehow critical..
    add_handlers(auth = PSYC.Handler.Auth(this, sendmmp, uni),
		 reply = PSYC.Handler.Reply(this, sendmmp, uni));
}

//! Send an @[MMP.Packet]. MMP routing variables of the packet will be set automatically if possible.
//! @param target
//!	The target to be used if there is not a target specified in @expr{packet@}.
//! 	Otherwise only the hostname of this will be used as the physical target, all other needed informations 
//!	will be fetched from @expr{packet@}.
//! @param packet
//! 	The @[MMP.Packet] to send.
void sendmmp(MMP.Uniform target, MMP.Packet packet) {
    P2(("PSYC.Unl", "%O->sendmmp(%O, %O)\n", this, target, packet))
    
    if (!has_index(packet->vars, "_context")) {
	if (!has_index(packet->vars, "_target")) {
	    packet["_target"] = target;
	}

	if (!has_index(packet->vars, "_source")) {
	    packet["_source"] = uni;
	}

	if (!has_index(packet->vars, "_counter")) {
	    packet["_counter"] = counter[packet["_source"]]++;
	}
    }

    server->deliver(target, packet);
}

//! Entry point for processing PSYC messages through this handler framework.
//! @param p
//! 	An @[MMP.Packet] containing parseable PSYC as a string or @[PSYC.Packet].
//!
//! 	This will do everything from throwing to nothing if you provide something else.
void msg(MMP.Packet p) {
    P3(("Unl", "%O: msg(%O)\n", this, p))
    
    object factory() {
	return JSON.UniformBuilder(this->server->get_uniform);
    };

    mixed parse_JSON(string d) {
	return JSON.parse(d, 0, 0, ([ '\'' : factory ]));
    };
    
    if (p->data) {
	if (stringp(p->data)) {
#ifdef LOVE_TELNET
	    p->data = PSYC.parse(p->data, parse_JSON, p->newline);
#else
	    p->data = PSYC.parse(p->data, parse_JSON);
#endif
	}
    } else {
	P1(("Unl", "%O: got packet without data. maybe state changes\n"))
	return;
    }

    handle("prefilter", p, ([]));
}
