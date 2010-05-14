mapping(MMP.Uniform:object) channels = ([]);

class Channel {
    mapping(MMP.Uniform:int) members = ([]);
    void sendmsg() {
    }

    void add_member(MMP.Uniform u) {
	members[u] = 1;
    }

    void remove_member(MMP.Uniform u) {
	m_delete(members, u);
    }
}

int _request_context_enter(MMP.Packet p, PSYC.Message m) {
}

int _notice_context_leave(MMP.Packet p, PSYC.Message m) {
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
