// vim:syntax=lpc
class Channel() {
    mapping(object:mapping(MMP.Uniform:int)) routes = ([]);

    MMP.Utils.QuotaMap history = MMP.Utils.QuotaMap(20);

    void add_route(MMP.Uniform target, object o) {
	if (!has_index(routes, o)) {
	    routes[o] = ([ target : 1 ]);
	} else {
	    routes[o][target] = 1;
	}
    }

    void remove_route(MMP.Uniform target, object o) {
	if (has_index(routes, o)) {
	    m_delete(routes[o], target);

	    if (!sizeof(routes[o])) m_delete(routes, o);
	}
    }

    void msg(MMP.Packet p) {
	history[p->vars->_id] = p;
	foreach (routes; object route; ) {
	    call_out(route->msg, 0, p);
	}
    }
}

mapping(MMP.Uniform:object) channels = ([]);

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
	    this->sendreply(p, rm);
	    get_channel(m->vars->_channel)->add_route(m->vars->_supplicant, this->server->get_route(m->vars->_supplicant));
	} else {
	    this->sendreply(p, rm);
	}
    };
	
    if (this->server->is_local(m->vars->_channel)) {
	this->sendmsg(m->vars->_channel, "_request_context_enter", 0, ([ "_supplicant" : m->vars->_supplicant ]), cb);
    } else {
	MMP.Uniform target = this->server->get_uniform(m->vars->_channel->root);
	this->send(target, m, 0, cb);
    }

    return PSYC.STOP;
}

int _notice_context_leave(MMP.Packet p, PSYC.Message m) {
    void cb(MMP.Packet rp, PSYC.Message rm) {
	if (rm->method == "_notice_context_leave") {
	    this->sendreply(p, rm);
	} else {
	    this->sendreply(p, rm);
	}
    };

    get_channel(m->vars->_channel)->remove_route(m->vars->_supplicant, this->server->get_route(m->vars->_supplicant));
	
    if (this->server->is_local(m->vars->_channel)) {
	this->send(m->vars->_channel, m, 0, cb);
    } else {
	MMP.Uniform target = this->server->get_uniform(m->vars->_channel->root);
	this->send(target, m, cb);
    }

    return PSYC.STOP;
}

int _request_context_retrieval(MMP.Packet p, PSYC.Message m) {

    object chan = get_channel(m->vars->_channel);
    array(MMP.Packet) a = ({});
    array(int) b = ({ });

    werror("CONTEXT retransmission of %O\n", m->vars->_ids);

//    a = filter(map(m->vars->_ids, chan->history->`[]));

    foreach (m->vars->_ids;; int id) {
	if (has_index(chan->history, id)) {
	    a += ({ chan->history[id] });
	} else {
	    b += ({ id });
	}
    }

    if (sizeof(a)) this->sendreply(p, this->List(this->Packet(this->Atom()))->encode(a));

    werror("CONTEXT retransmissing:\n%O\n", a);
    werror("CONTEXT history:\n%O\n", chan->history->m);

    return PSYC.STOP;
}

int _notice_channel_enter(MMP.Packet p, PSYC.Message m) {
    // TODO
}
