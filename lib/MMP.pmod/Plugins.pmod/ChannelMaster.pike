mapping(MMP.Uniform:object) channels = ([]);

class Channel(object server, MMP.Uniform uniform) {
    mapping(MMP.Uniform:int) members = ([]);
    int id = 0;

    void castmsg(string method, void|string data, void|mapping vars, void|mapping relay) {
	mapping mv = (relay||([])) + ([
	    "_context" : uniform,
	    "_id" : id++,
	]);
	server->msg(MMP.Packet(PSYC.Message(method, data, vars), mv);
    }

    void add_member(MMP.Uniform u) {
	members[u] = 1;
    }

    void remove_member(MMP.Uniform u) {
	m_delete(members, u);
    }
}

int _request_context_enter(MMP.Packet p, PSYC.Message m) {
    MMP.Uniform member = m->vars->_supplicant;
    object chan = get_channel();

    chan->add_member(member);
    // check if coming from our root
    this->sendreplymsg(p, "_notice_context_enter");
    // TODO: send _notice_context_enter in context
}

int _notice_context_leave(MMP.Packet p, PSYC.Message m) {
    // TODO: remove from all channels, or this should be explicit
    get_channel()->remove_member(m->vars->_supplicant);
}

// user stopped existing. wipe from rooms
int _failure_delivery_permanent(MMP.Packet p, PSYC.Message m) {
    get_channel()->remove_member(m->vars->_target);
}

object get_channel(void|string|MMP.Uniform chan) {
    MMP.Uniform u;
    object channel;

    if (!chan) u = this->uniform;
    else if (stringp(chan)) {
	u = this->server->get_uniform((this->uniform->channel) ? this->uniform->unl[0..sizeof(this->uniform->unl)-sizeof(this->uniform->channel)]+"#"+chan : this->uniform->unl + "#" + chan);
    } else {
	u = chan;
    }


    if (!(channel = channels[u])) {
	channels[u] = channel = Channel(this->server, u);
    }

    return channel;
}
