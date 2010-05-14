// vim:syntax=lpc
class Channel() {
    mapping(object:int|mapping(MMP.Uniform:int)) routes = ([]);

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
	foreach (routes;; object route) {
	    call_out(route->msg, 0, p);
	}
    }
}

mapping(MMP.Uniform:object) channels = ([]);

object get_channel(MMP.Uniform u) {
    object chan = channels[u];

    if (!chan) {
	channels = chan = Channel();
	this->server->register_channel(u, chan);
    }

    return chan;
}

int _request_context_enter(MMP.Packet p, PSYC.Message m) {
    void cb(MMP.Packet rp, PSYC.Message rm) {
	if (rm->method == "_notice_context_enter") {
	    this->server->sendreplymsg(p, "_notice_context_enter");
	    get_channel(m->vars->_channel)->add_route(m->vars->_supplicant, this->server->get_route(m->vars->_supplicant));
	} else {
	    this->server->sendreply(p, rm);
	}
    };
	
    if (this->server->is_local(m->vars->_channel)) {
	this->sendmsg(m->vars->_channel, "_request_context_enter", 0, ([ "_supplicant" : m->vars->_supplicant ]), cb);
    } else {
	MMP.Uniform target = this->server->get_uniform(m->vars->_channel->root);
	this->send(target, m, cb);
    }

    return PSYC.STOP;
}

int _notice_channel_enter(MMP.Packet p, PSYC.Message m) {
    // TODO
}
