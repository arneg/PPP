// vim:syntax=lpc
#define client	Protocols.DNS->global_async_client
//#define MVC(MAP, VAL)	#VAL : MAP->VAL

void async_srv(string service, string protocol, string name, function cb,
	       mixed ... cba) {
    void sort_srv(string query, mapping result) {
	int(0..1) sorter(mapping a, mapping b) {
	    if (a->priority == b->priority) {
		return a->weight < b->weight;
	    } else {
		return a->priority > b->priority;
	    }
	};

	array(mapping) res;

	if (result && sizeof(res = [array(mapping)]result->an)) {
	    if (`==(@res->type, Protocols.DNS.T_SRV) == 1) {
		res = [array(mapping)]Array.sort_array(res, sorter);
		cb(query, res, @cba);
	    } else {
		// TODO:: if this should happen alot, and not all answers are
		// of the same (wrong) type, change strategy to "fixing"
		// the answers. probably.
		cb(-2, @cba);
		werror("dns client: error-prone reply\n");
	    }
	} else {
	    cb(-1, @cba);
	    werror("dns client: no result\n");
	}
    };

    if (!client) client = Protocols.DNS.async_client();

    client->do_query("_" + service +"._"+ protocol + "." + name,
                        Protocols.DNS.C_IN,
                        Protocols.DNS.T_SRV, sort_srv);
}
