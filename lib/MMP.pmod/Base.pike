object server;
MMP.Uniform uniform;

void create(object server, MMP.Uniform uniform) {
    this_program::server = server;
    this_program::uniform = uniform;
}

int(0..1) authenticate(MMP.Uniform u) {
	return u == uniform;
}

void sendmsg(MMP.Uniform target, string method, void|string data, void|mapping vars, void|function callback);

// TODO: these mmp objects are not really capable of doing the _request_retrieval, so we should probably have a
// callback for that. or something. lets assume we have a sendmsg
int msg(MMP.Packet p, function callback) {
	return PSYC.GOON;
}

void send(MMP.Uniform target, Serialization.Atom m, void|mapping vars) {
	if (target == uniform) {
	    werror("dropping packet %O send to ourselves.\n", m);
	    return;
	}
	if (!vars) vars = ([]);
	vars = ([ 
		"_source" : uniform, 
		"_target" : target,
	]) + vars;

	//werror("send(%s, %O)\n", m->type, vars);

	MMP.Packet p = MMP.Packet(m, vars);
	server->msg(p);
}

void sendreply(MMP.Packet p, Serialization.Atom m, void|mapping vars) {
	p = p->reply(m);
	MMP.Uniform target = p->vars->_target;

	p->vars += ([ 
		"_source" : uniform, 
	]);

	if (vars) p->vars += vars;

	//werror("send(%s, %O)\n", m->type, p->vars);

	server->msg(p);
}

void mcast(Serialization.Atom a, void|string channel) {
    	// how do we handle _id and so on in case of multicast messages?
	server->msg(MMP.Packet(a, ([ "_context" : uniform ])));
}
