inherit Serialization.Signature;
inherit Serialization.PsycTypes;

object session, unl, psyc_server;
object parser;

void create(mapping params) {
    this_program::session = params["meteor_session"];
    this_program::unl = params["uniform"];
    this_program::psyc_server = params["server"];

    session->cb = handle;

    ::create(params["type_cache"]);

    parser = MMPPacket(Atom(), Atom());
}

void msg(MMP.Packet p) {
    Serialization.Atom a;
    if (p->signature) {
	a = p->signature->encode(p);
    } else {
	error("packet without signature, cannot encode.\n");
    }

    session->send(a);
}

void handle(Serialization.Atom a, object s) {
    MMP.Packet p = parser->decode(a);

    MMP.Uniform target = p["_target"];

    if (!target) {
	// this means that we do not support multicast messages right now.
	error("Meteor gateway received packet without _target.\n");
    }

    p["_source"] = unl;
    psyc_server->deliver(target, p);
}
