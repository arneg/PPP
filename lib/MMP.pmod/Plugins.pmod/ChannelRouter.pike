// vim:syntax=lpc
inherit .Base;

class Channel() {
    mapping(object:mapping(MMP.Uniform:int)) routes = ([]);

    MMP.Utils.QuotaMap history = MMP.Utils.QuotaMap(20);

    object hmac = Crypto.HMAC(Crypto.SHA1())(random_string(20));

    void add_route(MMP.Uniform target, object o) {
	if (!has_index(routes, o)) {
	    routes[o] = ([ target : 1 ]);
	} else {
	    routes[o][target] = 1;
	}
    }

    string get_token(int id) {
	return hmac(sprintf("%d", id));
    }

    function(int:int(0..1)) check_token(string token, int id) {
	int (0..1) _cb_true(int desired_id) {
	    return id <= desired_id;
	};

#if 0
	int (0..1) _cb_false(int desired_id) {
	    return 0;
	};
#endif

	return hmac(sprintf("%d", id)) == token ? _cb_true : 0;
    }

    void remove_route(MMP.Uniform target, object o) {
	if (has_index(routes, o)) {
	    m_delete(routes[o], target);

	    if (!sizeof(routes[o])) m_delete(routes, o);
	}
    }

    int(0..1) has_member(object o, MMP.Uniform target) {
	return has_index(routes, o) && has_index(routes[o], target);
    }

    void msg(MMP.Packet p) {
	werror("mcast(%s, %O)\n", p->data->type, p);
	history[p->vars->_id] = p;

	foreach (routes; object route; ) {
	    call_out(route->msg, 0, p);
	}
    }
}

mapping(MMP.Uniform:object) channels = ([]);
object retrieval_sig;

void create(object server, MMP.Uniform uniform) {
    retrieval_sig = this->List(this->Packet(this->Atom()));
}

object get_channel(MMP.Uniform u) {
    object chan = channels[u];

    if (!chan) {
	channels[u] = chan = Channel();
	this->server->register_channel(u, chan);
    }

    return chan;
}

int _request_context_enter(MMP.Packet p, PSYC.Message m) {
    void cb(MMP.Packet rp, PSYC.Message rm) {
	if (rm->method == "_notice_context_enter") {
	    int id = rm->vars->_context_id;
	    int max = rm->vars->_history_max;
	    object chan = get_channel(m->vars->_channel);
	    string token = chan->get_token(predef::max(0, id-max));
	    sendreply(p, PSYC.Message(rm->method, rm->data, rm->vars + ([ "_token" : token, "_id" : predef::max(0, id-max) ])));
	    get_channel(m->vars->_channel)->add_route(m->vars->_supplicant, this->server->get_route(m->vars->_supplicant));
	} else {
	    sendreply(p, rm);
	}
    };
	
    if (this->server->is_local(m->vars->_channel)) {
	sendmsg(m->vars->_channel, "_request_context_enter", 0, ([ "_supplicant" : m->vars->_supplicant ]), cb);
    } else {
	MMP.Uniform target = this->server->get_uniform(m->vars->_channel->root);
	send(target, m, 0, cb);
    }

    return PSYC.STOP;
}

int _notice_context_leave(MMP.Packet p, PSYC.Message m) {
    void cb(MMP.Packet rp, PSYC.Message rm) {
	if (rm->method == "_notice_context_leave") {
	    sendreply(p, rm);
	} else {
	    sendreply(p, rm);
	}
    };

    get_channel(m->vars->_channel)->remove_route(m->vars->_supplicant, this->server->get_route(m->vars->_supplicant));
	
    if (this->server->is_local(m->vars->_channel)) {
	send(m->vars->_channel, m, 0, cb);
    } else {
	MMP.Uniform target = this->server->get_uniform(m->vars->_channel->root);
	send(target, m, 0, cb);
    }

    return PSYC.STOP;
}

int _request_context_retrieval(MMP.Packet p, PSYC.Message m) {

    object chan = get_channel(m->vars->_channel);
    array(MMP.Packet) a = ({});
    array(int) b = ({ });
    function ct = chan->check_token(m->vars->_token, m->vars->_id);

//    a = filter(map(m->vars->_ids, chan->history->`[]));

    if (!chan->has_member(this->server->get_route(p->source()), p->source())) { // TODO:: may route change?
	return PSYC.STOP;
    }

    if (ct) foreach (m->vars->_ids;; int id) {
	if (!ct(id)) continue;
	if (has_index(chan->history, id)) {
	    a += ({ chan->history[id] });
	} else {
	    b += ({ id });
	}
    }

    if (sizeof(b)) {
	int cb(MMP.Packet rp, PSYC.Message rm) {
	    array(MMP.Packet) na = retrieval_sig->decode(rp->data);
	    foreach (na;;MMP.Packet p) {
		chan->history[p->vars->_id] = p;
	    }

	    if (sizeof(a)) {
		sendreply(p, retrieval_sig->encode(na+a));
	    } else {
		sendreply(p, rp->data);
	    }

	    return PSYC.STOP;
	};

	if (this->server->is_local(m->vars->_channel)) {
	    sendmsg(m->vars->_channel, "_request_context_retrieval", 0, ([ "_ids" : b ]), cb);
	} else {
	    MMP.Uniform target = this->server->get_uniform(m->vars->_channel->root);
	    send(target, m, 0, cb);
	}
    } else if (sizeof(a)) sendreply(p, retrieval_sig->encode(a));

    return PSYC.STOP;
}

int _notice_channel_enter(MMP.Packet p, PSYC.Message m) {
    // TODO
}
