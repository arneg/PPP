#include <new_assert.h>
inherit PSYC.Handling;
inherit PSYC.HandlingTools;

object storage;

//! @seealso
//! 	@[PSYC.Storage.File], @[PSYC.Storage.Remote], @[PSYC.Storage.Dummy]
void create(mapping params) {
    function _sendmmp;

    enforce(objectp(storage = params["storage"]));
    enforce(functionp(_sendmmp = params["sendmmp"]));

    void sendmmp(MMP.Uniform target, MMP.Packet p) {
	if (!has_index(p->vars, "_source")) {
	    p["_source"] = uni;
	}

	_sendmmp(target, p);
    };

    ::create(params + ([ "sendmmp" : sendmmp ]));
    debug("local_objects", 5, "created Channel(%s).\n", uni);

    mapping handling_params = params + ([
	"handling" : this,	
    ]);

    PSYC.MethodMultiplexer(handling_params);
    PSYC.NotifyHandling(handling_params);
    PSYC.CastHandling(handling_params);
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
    debug("packet_flow", 4, "%O: msg(%O)\n", this, p);

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
	debug("packet_flow", 2, "%O: got packet without data. maybe state changes\n");
	return;
    }

    handle("prefilter", p, ([]));
}
