class State {
    int local_id = 0;
    int remote_id = -1; 
    int last_in_sequence = 0;

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

void sendmsg(MMP.Uniform target, string method, void|string data, void|mapping vars);

// TODO: these mmp objects are not really capable of doing the _request_retrieval, so we should probably have a
// callback for that. or something. lets assume we have a sendmsg
void msg(MMP.Packet p) {
	int id = p["_id"];
	int ack = p["_ack"];
	object state = get_state(p["_source"]);

	werror("%O received %d (ack: %d, remote: %d, seq: %d)\n", uniform, id, ack, state->remote_id, state->last_in_sequence);

	if (id == 0) {
	    // this is the special reinitialization case. we need to drop all missing
	    // and cached aswell.
	}

	if (id == state->last_in_sequence + 1) {
	    if (!sizeof(state->missing)) state->last_in_sequence = id;
	    state->remote_id = id;
	} else if (id > state->remote_id + 1) { // missing messages
	    // we will request retrieval only once
	    // maybe use missing = indices(state->missing) here?
	    array(int) missing = enumerate(id - state->remote_id - 1, 1, state->remote_id + 1);
	    state->missing += mkmapping(missing, allocate(sizeof(missing), 1));
	    sendmsg(p["_source"], "_request_retrieval", 0, ([ "_ids" : missing ]));
	    state->remote_id = id;
	} else if (id <= state->remote_id) { // retrieval
	    if (has_index(state->missing, id)) {
		m_delete(state->missing, id);
		if (!sizeof(state->missing)) state->last_in_sequence = state->remote_id;
	    } else return; // we can drop it
	}



	// would like to use something like filter(state->cache, Function.curry(`>)(ack)) ...
	for (int i = ack; has_index(state->cache, i); i--) m_delete(state->cache, i);
}

void send(MMP.Uniform target, Serialization.Atom m, void|MMP.Uniform relay) {
	object state = get_state(target);
	int id = state->get_id();
	mapping vars = ([ 
		"_source" : uniform, 
		"_target" : target,
		"_id" : id,
		"_ack" : state->last_in_sequence,
	]);

	if (relay) {
		vars["_source_relay"] = relay;
	}

	MMP.Packet p = MMP.Packet(m, vars);
	state->cache[id] = p;
	server->msg(p);
}

void mcast(Serialization.Atom a, void|string channel) {
    	// how do we handle _id and so on in case of multicast messages?
	server->msg(MMP.Packet(a, ([ "_context" : uniform ])));
}
