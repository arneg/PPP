#include <debug.h>
#include <assert.h>
inherit PSYC.Handling;
inherit PSYC.HandlingTools;

object storage;

//! @seealso
//! 	@[PSYC.Storage.File], @[PSYC.Storage.Remote], @[PSYC.Storage.Dummy]
void create(mapping prefs) {
    P2(("PSYC.Channel", "created object for %s.\n", prefs["uniform"]))
    function _sendmmp;

    assert(objectp(prefs["storage"]));
    assert(objectp(prefs["parent"]));
    assert(MMP.is_uniform(prefs["uniform"]));
    assert(functionp(prefs["sendmmp"]));
    _sendmmp = prefs["sendmmp"];

    storage = prefs["storage"];
    PSYC.MethodMultiplexer(this, storage);
    PSYC.NotifyHandling(this, storage);
    PSYC.CastHandling(this, storage);
    PSYC.CheckHandling(this, storage);

    void sendmmp(MMP.Uniform target, MMP.Packet p) {
	if (!has_index(p->vars, "_source")) {
	    p["_source"] = uni;
	}

	_sendmmp(target, p);
    };

    ::create(prefs["parent"], sendmmp, prefs["uniform"]);
}

void castmsg(MMP.Packet p, MMP.Uniform source_relay) {
    parent->castmsg(uni, p, source_relay);     
}

// copied here from Unl.pike.
//! Entry point for processing PSYC messages through this handler framework.
//! @param p
//! 	An @[MMP.Packet] containing parseable PSYC as a string or @[PSYC.Packet].
//!
//! 	This will do everything from throwing to nothing if you provide something else.
void msg(MMP.Packet p) {
    P3(("Channel", "Channel(%O): msg(%O)\n", uni, p))
    
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
