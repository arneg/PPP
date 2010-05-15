mapping(MMP.Uniform:object) channels = ([]);

class Channel(object server, MMP.Uniform uniform) {
    mapping(MMP.Uniform:int) members = ([]);

    MMP.Utils.QuotaMap history = MMP.Utils.QuotaMap(20);

    int id = 0;

    function on_enter, on_leave;

    void groupcast(Serialization.Atom a, void|mapping relay) {
	mapping mv = (relay||([])) + ([
	    "_context" : uniform,
	    "_id" : id,
	]);
	MMP.Packet p = MMP.Packet(a, mv);
	history[id++] = p;
	server->msg(p);
    }

    void add_member(MMP.Uniform u) {
	if (on_enter && !has_index(members, u)) on_enter(u);
	members[u] = 1;
    }

    void remove_member(MMP.Uniform u) {
	if (on_leave && has_index(members, u)) on_leave(u);
	m_delete(members, u);
    }

    int(0..1) has_member(MMP.Uniform u) {
	return has_index(members, u);
    }
}

int _request_context_enter(MMP.Packet p, PSYC.Message m, function|void cb) {
    MMP.Uniform member = m->vars->_supplicant;
    object chan = get_channel();

    chan->add_member(member);
    // check if coming from our root
    this->sendreplymsg(p, "_notice_context_enter", 0, ([ "_context_id" : chan->id, "_members" : indices(chan->members), "_history_max" : chan->history->max ]));
    // TODO: send _notice_context_enter in context

    return PSYC.STOP;
}

int _request_context_retrieval(MMP.Packet p, PSYC.Message m, function|void cb) {
    array(MMP.Packet) a = filter(map(m->vars->_ids, get_channel()->history->`[]), Function.curry(`!=)(0));
    this->sendreply(p, this->List(this->Packet(this->Atom()))->encode(a));
}

int _notice_context_leave(MMP.Packet p, PSYC.Message m) {
    // TODO: remove from all channels, or this should be explicit
    get_channel()->remove_member(m->vars->_supplicant);

    this->sendreplymsg(p, "_notice_context_enter");

    return PSYC.STOP;
}

// user stopped existing. wipe from rooms
int _failure_delivery_permanent(MMP.Packet p, PSYC.Message m) {
    get_channel()->remove_member(m->vars->_target);

    return PSYC.STOP;
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
