// vim:syntax=lpc
// psyc root object. does most routing, multicast signalling etc.
//

inherit PSYC.Unl;

void create(MMP.Uniform uniform, object server, PSYC.Storage storage) {
    ::create(uniform, server, storage);

    add_handlers(Circuit(this));
}

class Circuit {

    inherit PSYC.Handler.Base;

    constant _ = ([
	"postfilter" : ([
	    "_notice_circuit_established" : 0,
	    "_status_circuit" : 0,
	]),
    ]);

    int postfilter_notice_circuit_established(MMP.Packet p, mapping _v, mapping _m) {
	// TODO: is a _source_identification valid here _at all_ ? doesnt make too much sense.
	server->add_route(p->source(), p->source()->handler);

	return PSYC.Handler.STOP;
    }

    int postfilter_status_circuit(MMP.Packet p, mapping _v, mapping _m) {
	p->source()->handler->activate();

	return PSYC.Handler.STOP;
    }

}

#if 0
void msg(MMP.Packet packet) {

    if (::msg(packet)) return;

    MMP.Uniform source = packet["_source"];

    P2(("PSYC.Server", "rootmsg(%O) from %O\n", packet, connection))
    if (packet->data) {
	PSYC.Packet message = packet->data;

	switch (message->mc) {
	    // ich weiss nichtmehr so genau. in FORK wird das eh alles
	    // anders.. ,)
	case "_notice_circuit_established":
	    server->add_route(source->host+" "+(string)(source->port||4404), connection);
	case "_status_circuit":
	    // auch hier nicht sicher
	    
	    source->handler->activate();
	    break;
	default:
	    return;
	}
    } else { // hmm

    }
}
#endif
