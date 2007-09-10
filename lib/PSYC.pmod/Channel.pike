#include <debug.h>
#include <assert.h>
inherit PSYC.MethodMultiplexer : multiplexer;
inherit PSYC.HandlingTools : handling;

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

    multiplexer::create(prefs["storage"]);

    void sendmmp(MMP.Uniform target, MMP.Packet p) {
	if (!has_index(p->vars, "_source")) {
	    p["_source"] = uni;
	}

	_sendmmp(target, p);
    };

    handling::create(prefs["parent"], sendmmp, prefs["uniform"]);
}

void castmsg(MMP.Packet p) {
    parent->castmsg(uni, p);     
}
