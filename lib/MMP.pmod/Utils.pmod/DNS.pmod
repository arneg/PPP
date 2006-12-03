// vim:syntax=lpc
#define client	Protocols.DNS->global_async_client
//#define MVC(MAP, VAL)	#VAL : MAP->VAL

void async_srv(string service, string protocol, string name, function cb,
	       mixed ... cba) {
    void sort_srv(string query, mapping result) {
	array(mapping) res;

	if (result) {
	    if (sizeof(res = [array(mapping)]result->an)) {
		if (`==(@res->type, Protocols.DNS.T_SRV) == 1) {
		    mapping(int : array(mapping)) tmp = ([ ]), tmp2 = ([ ]);

		    foreach (res;; mapping m) {
			if (!tmp[m->priority]) {
			    tmp[m->priority] = ({ });
			    tmp2[m->priority] = ({ });
			}

			tmp[m->priority] += ({ m });
		    }

		    res = ({ });

		    foreach (sort(indices(tmp));; int index) {
			sort(tmp[index]->weight, tmp[index]);

			while (sizeof(tmp[index])) {
			    int probability = random(`+(@tmp[index]->weight)
						     + 1);

			    foreach (tmp[index]; int i; mapping m) {
				probability -= m->weight;

				if (probability <= m->weight) {
				    res += ({ m });
				    tmp[index] = tmp[index][..i - 1]
					    + tmp[index][i + 1..];
				    break;
				}
			    }
			}
		    }

		    //res = [array(mapping)]Array.sort_array(res, sorter);
		    cb(query, res, @cba);
		} else {
		    // TODO:: if this should happen alot, and not all answers
		    // are of the same (wrong) type, change strategy to "fixing"
		    // the answers. probably.
		    cb(query, -2, @cba);
		    werror("dns client: error-prone reply\n");
		}
	    } else {
		cb(query, res, @cba);
	    }
	} else {
	    cb(query, -1, @cba);
	    werror("dns client: no result\n");
	}
    };

    if (!client) client = Protocols.DNS.async_client();

    client->do_query("_" + service +"._"+ protocol + "." + name,
                        Protocols.DNS.C_IN,
                        Protocols.DNS.T_SRV, sort_srv);
}
