class State {
    int local_id = 0;
    int remote_id = -1; 
    int last_in_sequence = -1;

    mapping(int:int) missing = ([]);
    mapping(int:MMP.Packet) cache = ([]);

    int get_id() {
		return local_id++;
    }
}

mapping(MMP.Uniform:State) states = ([]);

object server;
MMP.Uniform uniform;

void create(object server, MMP.Uniform uniform) {
    this_program::server = server;
    this_program::uniform = uniform;
}

State get_state(MMP.Uniform u) {
    State state = states[u];

    if (!state) {
	states[u] = state = State();
    }

    return state;
}

int(0..1) authenticate(MMP.Uniform u) {
	return u == uniform;
}

void delete_state(MMP.Uniform u) {
    m_delete(states, u);
}

void sendmsg(MMP.Uniform target, string method, void|string data, void|mapping vars, void|function callback);

// TODO: these mmp objects are not really capable of doing the _request_retrieval, so we should probably have a
// callback for that. or something. lets assume we have a sendmsg
int msg(MMP.Packet p, function callback) {
	if (has_index(p->vars, "_context")) return PSYC.GOON;

	int id = p["_id"];
	int ack = p["_ack"];

	object state = get_state(p["_source"]);

	if (0 == id && state->remote_id != -1) {
	    //werror("%O received initial packet from %O\n", uniform, p["_source"]);
	    delete_state(p["_source"]);
	    state = get_state(p["_source"]);
	    // TODO we should check what happened to _ack. maybe we dont have to throw
	    // away all of it
	}

	//werror("%O received %d (ack: %d, remote: %d, seq: %d)\n", uniform, id, ack, state->remote_id, state->last_in_sequence);

	if (id == state->remote_id + 1) {
	    if (state->last_in_sequence == state->remote_id) state->last_in_sequence = id;
	} else if (id > state->remote_id + 1) { // missing messages
	    // we will request retrieval only once
	    // maybe use missing = indices(state->missing) here?
	    array(int) missing = enumerate(id - state->remote_id - 1, 1, state->remote_id + 1);
	    werror("missing: %O\n", missing);
	    state->missing += mkmapping(missing, allocate(sizeof(missing), 1));
	    call_out(sendmsg, 0, p["_source"], "_request_retrieval", 0, ([ "_ids" : indices(state->missing) ]));
	    state->remote_id = id;
	} else if (id <= state->remote_id) { // retrieval
	    werror("got retransmission of %d (still missing: %s)\n", id, (array(string))indices(state->missing) * ", ");
	    if (has_index(state->missing, id)) {
		m_delete(state->missing, id);
		if (!sizeof(state->missing)) state->last_in_sequence = state->remote_id;
		else state->last_in_sequence = min(@indices(state->missing))-1;
	    } return PSYC.STOP;
	}

	if (id > state->remote_id) state->remote_id = id;

	// would like to use something like filter(state->cache, Function.curry(`>)(ack)) ...
	for (int i = ack; has_index(state->cache, i); i--) m_delete(state->cache, i);

	return PSYC.GOON;
}

void send(MMP.Uniform target, Serialization.Atom m, void|mapping vars) {
	object state = get_state(target);
	int id = state->get_id();
	if (!vars) vars = ([]);
	vars = ([ 
		"_source" : uniform, 
		"_target" : target,
		"_id" : id,
		"_ack" : state->last_in_sequence,
	]) + vars;

	//werror("send(%s, %O)\n", m->type, vars);

	MMP.Packet p = MMP.Packet(m, vars);
	state->cache[id] = p;
	server->msg(p);
}

void sendreply(MMP.Packet p, Serialization.Atom m, void|mapping vars) {
	p = p->reply(m);
	MMP.Uniform target = p->vars->_target;

	object state = get_state(target);
	int id = state->get_id();

	p->vars += ([ 
		"_source" : uniform, 
		"_id" : id,
		"_ack" : state->last_in_sequence,
	]);

	if (vars) p->vars += vars;

	//werror("send(%s, %O)\n", m->type, p->vars);

	state->cache[id] = p;
	server->msg(p);
}

void mcast(Serialization.Atom a, void|string channel) {
    	// how do we handle _id and so on in case of multicast messages?
	server->msg(MMP.Packet(a, ([ "_context" : uniform ])));
}
