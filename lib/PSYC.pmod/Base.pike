inherit MMP.Base;
inherit Serialization.Signature;
inherit Serialization.PsycTypes;

object msig;

void create(object server, MMP.Uniform uniform) {
    ::create(server, uniform);

    msig = Message(); // whatever
}

void msg(MMP.Packet p) {
    ::msg(p);


    if (msig->can_decode(p->data)) { // this is a psyc mc or something
	string method = p->data->type;
	PSYC.Message m;

	if (method[0] == '_') {
	    mixed f = this[method];
	    
	    if (functionp(f)) {
		if (!m) m = decode_message(p->data);
		if (PSYC.STOP == f(p, m)) return;
	    }

	    array(string) t = method/"_";

	    for (int i = sizeof(t)-2; i > 0; i--) {
		f = this[t[0..i]*"_"];
		if (functionp(f)) {
		    if (!m) m = decode_message(p->data);
		    if (PSYC.STOP == f(p, m)) return;
		}
	    }

	    f = this->_;

	    if (functionp(f)) {
		if (!m) m = decode_message(p->data);
		if (PSYC.STOP == f(p, m)) return;
	    }
	}
    }
}

void sendmsg(MMP.Uniform target, string method, void|string data, void|mapping m) {
	send(target, PSYC.Message(method, data, m));
}

int _request_retrieval(MMP.Packet p, PSYC.Message m) {
    array ids = m["_ids"];

    object state = get_state(p->source());

    foreach (ids;;int i) {
	MMP.Packet packet = state->cache[i];
	if (!packet) werror("Packet with id %d not available for retransmission\n", i);
	else send(packet);
    }

    return PSYC.GOON;
}
