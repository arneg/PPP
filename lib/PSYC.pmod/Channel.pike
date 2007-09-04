inherit PSYC.MethodMultiplexer : multiplexer;
inherit PSYC.HandlingTools : handling;

//! @seealso
//! 	@[PSYC.Storage.File], @[PSYC.Storage.Remote], @[PSYC.Storage.Dummy]
void create(mapping prefs) {
    P2(("PSYC.Channel", "created object for %s.\n", u))

    assert(objectp(prefs["storage"]));
    assert(objectp(prefs["parent"]));
    assert(MMP.Utils.is_uniform(prefs["uniform"]));
    assert(functionp(prefs["sendmmp"]));

    multiplexer::create(prefs["storage"]);
    handling::create(prefs["parent"], prefs["sendmmp"], prefs["uniform"]);
}

void castmsg(MMP.Packet p) {
    parent->castmsg(uni, p);     
}

void sendmmp(MMP.Uniform target, MMP.Packet p) {
    if (!has_index(p->vars, "_source")) {
	p["_source"] = uni;
    }

    uni->sendmmp(target, p);
}
