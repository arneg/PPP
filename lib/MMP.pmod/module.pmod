// vim:syntax=lpc
//
#include <debug.h>
// generating a backtrace for a _normal_ throw is a bit too much...
void debug(string cl, string format, mixed ... args) {
    // erstmal nix weiter
    predef::werror("(%s)\t"+format, cl, @args);
}

void warn(string cl, string format, mixed ... args) {

}

void fatal(string cl, string format, mixed ... args) {

}
#if DEBUG
# define THROW(s)        throw(({ (s), backtrace() }))
#else
# define THROW(s)        throw(({ (s), 0 }))
#endif

//! Implementation of Uniform (similar to UNLs) as described in
//! @[http://about.psyc.eu/Uniform].
//! 
//! @note
//!	Parsing of the Uniform is done automatically when variables
//!	are being accessed for the first time using @[`->()].
class Uniform {

    //! The Uniforms scheme. Could be @expr{"psyc"@} or @expr{"xmpp"@}.
    string scheme;

    //! The domain name or ip adress of the Uniform.
    string host;

    //! The (optional) port. Will be 0 if none is given which will
    //! then be used as 4404, the standard PSYC port.
    int port;

    string transport;

    //! The user (if preceding host, delimeted by @@, e.g.
    //! @expr{protocol://user@@host@}).
    string user;

    //! The resource, excluding the first @expr{/@}.
    //! @example
    //!	    MMP.Uniform("http://ppp.psyc.eu/foo#babar")->resource; // is "foo#babar"
    string resource;

    //! The full unl.
    string unl;

    //! The channel. See @[http://about.psyc.eu/Channels].
    //! @example
    //!	    MMP.Uniform("http://ppp.psyc.eu/foo#babar")->channel; // is "babar"
    //!	    MMP.Uniform("http://ppp.psyc.eu/foo")->channel; // is UNDEFINED
    string channel;

    //! The address of the entity a given channel resides on. Is @expr{UNDEFINED@} if the Uniform
    //! is not a channel.
    //! @example
    //!	    MMP.Uniform("http://ppp.psyc.eu/foo#babar")->super; // is MMP.Uniform("http://ppp.psyc.eu/foo")
    MMP.Uniform super;

    //! The Uniform of the root entity.
    //! @example
    //!	    MMP.Uniform("http://ppp.psyc.eu/foo#babar")->root; // is MMP.Uniform("http://ppp.psyc.eu/")
    //! @note
    //!	    The root Uniform is not automatically set. In case you are using 
    //!	    @[PSYC.Server] this is taken care of.
    MMP.Uniform root;

    //! The object associated with this Uniform. As @expr{root@} this variable is not set by default but
    //! may be used to store such information. In contrast to @expr{root@} it must not be exprected to
    //! contain the object when using @[PSYC.Server].
    array handler = ({ 0 });
    //array handler = set_weak_flag(({ 0 }), Pike.WEAK_VALUES);

    string slashes;
    string query;
    string body;
    string userAtHost;
    string pass;
    string hostPort;
    string circuit;
    string obj;
    int parsed, islocal = UNDEFINED, reconnectable = 1;

    //! @param unl
    //!	    The string representation of the Uniform.
    //! @param o
    //!	    The object to be associated with @expr{u@}. Will be stored in
    //!	    the variable @expr{handler@}.
    void create(string unl, object|void o) {
	this_program::unl = unl;
	if (o) {
	    handler[0] = o;
	}
    }

    int is_local() {
	if (zero_type(islocal)) {
	    // -> to trigger parsing
	    if (this->super) { 
		islocal = this->super->is_local();
	    } 

	    if (!zero_type(islocal)) return islocal;

	    if (this->root && this != root) {
		islocal = root->is_local();
	    }

	    return islocal;
	}

	return islocal;
    }

    mixed cast(string type) {
	if (type == "string") return unl;
    }

    string to_json() {
	return "'" + unl + "'";
    }

    string _sprintf(int type) {
	if (type == 's') {
	    return sprintf("MMP.Uniform(%s)", unl);
	} else if (type = 'O') {
#if defined(DEBUG) && DEBUG >= 10
	    return sprintf("MMP.Uniform(%O)", 
			   aggregate_mapping(@Array.splice(indices(this), values(this))));
#else 
	    return sprintf("MMP.Uniform(%s, %s)", unl, is_local() ? "local" : "remote");
#endif
	}

	return UNDEFINED;
    }

    mixed `->=(string key, mixed value) {
	if (key == "handler") {
	    return handler[0] = value;
	}

	return ::`->=(key, value);
    }

    mixed `->(string dings) {
	if (dings == "handler") {
	    return handler[0];
	}

	if (!parsed) {
	    switch (dings) {
		case "scheme":
		case "transport":
		case "host":
		case "user":
		case "resource":
		case "slashes":
		case "query":
		case "body":
		case "userAtHost":
		case "pass":
		case "hostPort":
		case "circuit":
		case "root":
		case "super":
		case "port":
		case "channel":
		case "islocal":
		case "obj":
		case "reconnectable":
		    parse();
	    }
	}

	return ::`->(dings);
    }

    void parse() {
	string s, t = unl;
	if (!sscanf(t, "%s:%s", scheme, t)) THROW(sprintf("this (%s) is not uniforminess", unl));
	slashes = "";
	switch(scheme) {
	case "sip":
		sscanf(t, "%s;%s", t, query);
		break;
	case "xmpp":
	case "mailto":
		sscanf(t, "%s?%s", t, query);
	case "telnet":
		break;
	default:
		if (t[0..1] == "//") {
			t = t[2..];
			slashes = "//";
		}
	}
	body = t;
	sscanf(t, "%s/%s", t, resource);

	if (!resource || 2 != sscanf(resource, "%s#%s", obj, channel)) {
	    obj = resource;
	    channel = UNDEFINED;
	    super = UNDEFINED;
	}

	userAtHost = t;
	if (sscanf(t, "%s@%s", s, t)) {
		if (!sscanf(s, "%s:%s", user, pass))
		    user = s;
	}
	hostPort = t;
	//if (complete) circuit = scheme+":"+hostPort;
	//root = scheme+":"+slashes+hostPort;
	if (sscanf(t, "%s:%s", t, s)) {
		if (sizeof(s) && s[0] == '-') {
		    s = s[1..];
		    reconnectable = 0;
		}
		if (!sscanf(s, "%d%s", port, transport))
		    transport = s;
	}

	host = t;

	parsed = 1;
    }
}

Uniform parse_uniform(string s) {
    return Uniform(s);
}

string|String.Buffer render_vars(mapping(string:mixed) vars, 
				 void|String.Buffer to) {
    String.Buffer p;
    // i do not remember what i needed the p for.. we could use to instead.
    if (to)
	p = to;	
    else 
	p = String.Buffer();

    function add = p->add;
    function putchar = p->putchar;

    if (mappingp(vars)) foreach (vars; string key; mixed val) {
	string mod;
	if (key[0] == '_') mod = ":";
	else mod = key[0..0];
	

	// should be possible to transport int 0. this should do. 
	// other zero_types (e.g. UNDEFINED) for empty vars.
	if (val || zero_type(val) == 0) {
	    if (key[0] == '_') putchar(':');
	    add(key);
	    putchar('\t');
	    
	    if (stringp(val))
		add(replace(val, "\n", "\n\t")); 
	    else if (arrayp(val))
		add(map(val, replace, "\n", "\n\t") * ("\n"+mod+"\t"));
	    else if (mappingp(val))
		throw("no syntax for mappings in mmp.");
	    else if (intp(val) || (objectp(val) && Program.inherits(object_program(val), Uniform)))
		add((string)val);
	    
	    putchar('\n');
	
	} else {
	    if (key[0] == '_') putchar(':');
	    add(key);
	    putchar('\n');
	}
    }
}

//! Render a @[Packet] into its string representation according to the
//! definition in @[http://psyc.pages.de/mmp.html].
//! @param packet
//!	The Packet to be rendered.
//! @param to
//!	A @[String.Buffer] to render @expr{packet@} into.
//! @returns
//!	Depending on whether a @[String.Buffer] was specified either
//!	a string or the @[String.Buffer] is returned.
string|String.Buffer render(Packet packet, void|String.Buffer to) {
    String.Buffer p;

    if (to)
	p = to;	
    else 
	p = String.Buffer();

    function add = p->add;
    function putchar = p->putchar;

    if (sizeof(packet->vars))
	MMP.render_vars(packet->vars, p);

    if (packet->data) { 
	putchar('\n');
    
	if (stringp(packet->data)) {
	    add(packet->data);
	} else {
	    // TODO: every object contained in data needs a 
	    // render(void|String.Buffer) method.
	    add((string)packet->data);
	}
	add("\n.\n");
    } else {
	add(".\n");
    }

    if (to)
	return p;
    return p->get();
}

array(object) renderRequestChain(array(object) modules, string hook) {
    mapping s2o = ([ ]), usedby = ([ ]);
    array(object) ret = ({ });

    foreach (modules, object tmp) {
	if (has_index(s2o, tmp->provides)) {
	    THROW(sprintf("only one object at a time can provide %O.\n", tmp->provides));
	}

	s2o[tmp->provides] = tmp;
    }

    void rec(string t, string current) {
	object o;
	mixed cb;

	o = s2o[t];
	usedby[t] = current;

	if (multisetp(cb = o->before)
	     || mappingp(cb = o->before) && multisetp(cb = cb[hook])) {
	    foreach (indices(cb), string dep) {
		if (has_index(usedby, dep)) {
		    if (usedby[dep] == current) {
			THROW("found a loop (see backtrace for path).\n");
		    }
		} else if (has_index(s2o, dep)) {
		    rec(dep, current);	
		}
	    }
	}

	ret += ({ o });
    };

    foreach (s2o; string s; mixed o) {
	if (!has_index(usedby, s))
	    rec(s, s);
    }

    return reverse(ret);
}

//! Implementation of an MMP Packet as descibed in 
//! @[http://about.psyc.eu/MMP].
class Packet {
    //! MMP Variables of the Packet. These variables are routing information.
    //! You can find a description of all variables and their meaning in
    //! @[http://psyc.pages.de/mmp.html].
    mapping(string:mixed) vars;

    //! Data contained in the Packet. Could be a @expr{string@} of arbitrary
    //! data or an object. Objects are expected to be subclasses of 
    //! @[PSYC.Packet] in many parts of the @[PSYC] code.
    string|object data;

    function parsed = 0, sent = 0; 
#ifdef LOVE_TELNET
    string newline;
#endif

    // experimental variable family inheritance...
    // this actually does not exactly what we want.. 
    // because asking for a _source should return even _source_relay 
    // or _source_technical if present...
    void create(void|string|object data, void|mapping(string:mixed) vars) {
	this_program::vars = vars||([]);
	this_program::data = data||0; 
    }

    mixed cast(string type) {
	if (type == "string") {
	    return MMP.render(this);
	}
    }

    string next() {
	return (string)this;
    }

    int has_next() { 
	return 0;
    }

    //! @returns
    //!	    A string representation of the unique Packet identification
    //!	    as described in @[http://www.psyc.eu/mmp.html].
    string id() {
	if (has_index(vars, "_context")) {
	    return (string)vars["_context"] + (string)vars["_counter"];
	}
	return (string)vars["_source"] + (string)vars["_target"] + (string)vars["_counter"];
    }

    string _sprintf(int type) {
	if (type == 'O') {
	    if (data == 0) {
		return "MMP.Packet(Empty)\n";
	    }

	    if (stringp(data)) {
		return sprintf("MMP.Packet(%O, '%.15s..' )\n", vars, data);
	    } else {
#if defined(DEBUG) && DEBUG > 2
		return sprintf("MMP.Packet(\n\t_target: %s\n\t_source: %s\n\t_context: %s | %O)\n", vars["_target"]||"0", vars["_source"]||"0", vars["_context"]||"0", data);
#else
		return sprintf("MMP.Packet(%O, %O)\n", vars, data);
#endif
	    }
	} else if (type == 's') {
	    // TODO: rendern
	}

	return UNDEFINED;
    }
    
    //! @returns
    //!	    The value of the variable @expr{id@}. In case the packet contains
    //!	    an object e.g., a @[PSYC.Packet], variables of the object may be
    //!	    accessed this way aswell.
    mixed `[](string id) {
	if (has_index(vars, id)) {
	    return vars[id];
	}

	if (!is_mmpvar(id) && objectp(data)) {
	    P3(("MMP.Packet", "Accessing non-mmp variable (%s) in an mmp-packet.\n", id))
	    return data[id];
	}

	return UNDEFINED;
    }

    //! Assign MMP variable @expr{id@} to @expr{val@}.
    //! @returns
    //!	    @expr{val@}
    //! @throws
    //!	    This method throws if @expr{id@} is not a MMP variable and the packet
    //!	    does not contain an object.
    mixed `[]=(string id, mixed val) {

	if (is_mmpvar(id)) {
	    return vars[id] = val;
	}
	
	if (objectp(data)) {
	    return data[id] = val;
	}

	THROW(sprintf("put psyc variable (%s) into mmp packet (%O).", id, this));
    }

#if 0
    mixed `->(mixed id) {
	switch(id) {
	    case "lsource":
		if (has_index(vars, "_source_relay")) {
		    mixed s = vars["_source_relay"];

		    if (arrayp(s)) {
			s = s[-1];
		    }

		    return s;
		}
	    case "source":
		if (has_index(vars, "_source_identification")) {
		    return vars["_source_identification"];
		}

		return vars["_source"];
	}

	return ::`->(id);
    }
#endif

    //! @returns
    //!	    The source of this packet i.e., the Uniform of the entity this 
    //!	    Packet originates from. This is not to be confused with the 
    //!	    technical source.
    //! @note
    //!	    @expr{_source_identification || _source@}
    MMP.Uniform source() {
	if (has_index(vars, "_source_identification")) {
	    return vars["_source_identification"];
	}

	return vars["_source"];
    }

    //! @returns
    //!	    The reply adress of this packet i.e., the Uniform of the entity
    //!	    that is meant to receive any reply to this Packet.
    //! @note
    //!	    @expr{_source_identification_reply || _source_reply || _source@}
    //! @seealso
    //!	    @[PSYC.Packet()->reply()]
    //! @example
    //!	    PSYC.Packet m = p->data; 
    //!	    sendmsg(p->reply(), m->reply("_notice_version"));
    MMP.Uniform reply() {
	return vars["_source_identification_reply"]
	    || vars["_source_reply"]
	    || vars["_source"];
    }

    //! @returns
    //!	    Returns the relay source of this packet, @[source()] otherwise.
    MMP.Uniform lsource() {
	if (has_index(vars, "_source_relay")) {
	    mixed s = vars["_source_relay"];

	    if (arrayp(s)) {
		s = s[-1];
	    }

	    return s;
	}

	return source();
    }

    //! @returns
    //!	    Returns the technical source of this packet, which is either 
    //!     _source or _context.
    MMP.Uniform tsource() {
	return vars["_source"] || vars["_context"];
    }

    // why do we need this? copy_value doesn't copy objects.
    //! Clones the @[Packet] - this basically means that a new @[Packet] with
    //! identical data and a first level copy of vars (@expr{vars + ([ ])@})
    //! is created and returned.
    //!
    //! @[Packets] may not be modified once they have been sent (if you
    //! received a @[Packet], someone else sent it to you...), so you need to
    //! clone it before you do any modifications.
    //!
    //! @seealso
    //!	    @[PSYC.Packet()->clone()]
    this_program clone() {
	this_program n = this_program(data, vars + ([ ]));

	// do we need to copy parsed, sent, newline?
#if 0
	n->parsed = parsed;
	n->sent = sent;
# ifdef LOVE_TELNET
	n->newline = newline;
# endif
#endif

	return n;
    }

}

// 0
// 1 means yes and merge it into psyc
// 2 means yes but do not merge

//! @returns
//!	@int
//!	    @value 0
//!		@expr{var@} is not an MMP variable.
//!	    @value 1
//!		@expr{var@} is an MMP variable that should be seen
//!		by the application layer.
//!	    @value 2
//!		@expr{var@} is an MMP variable that should be used
//!		by the routing layer of your program only.
//!	@endint
//! @seealso
//!	For a description of MMP variables see @[http://psyc.pages.de/mmp.html].
int(0..2) is_mmpvar(string var) {
    switch (var) {
    case "_target":
    case "_target_relay":
    case "_source":
    case "_source_relay":
    case "_source_location":
    case "_source_identification":
    case "_context":
    case "_length":
    case "_counter":
    case "_reply":
    case "_trace":
    case "_amount_fragments":
    case "_fragment":
	return 1;
    case "_encoding":
    case "_list_require_modules":
    case "_list_require_encoding":
    case "_list_require_protocols":
    case "_list_using_protocols":
    case "_list_using_modules":
    case "_list_understand_protocols":
    case "_list_understand_modules":
    case "_list_understand_encoding":
	return 2;
    }
    return 0;
}

//! Implementation of MMP Circuits as described nowhere really.
class Circuit {
    inherit MMP.Utils.Queue;

    //! The socket used.
    Stdio.File|Stdio.FILE socket;

    string|String.Buffer inbuf;
#ifdef LOVE_TELNET
    string dl;
#endif
    MMP.Utils.Queue q_neg = MMP.Utils.Queue();
    Packet inpacket;
    mapping(string:mixed) in_state = ([ ]);
    string|array(string) lastval; // mappings are not supported in psyc right
				  // now anyway..
    int lastmod, write_ready, write_okay; // sending may be forbidden during
					  // certain parts of neg
    string lastkey;

    //! @[MMP.Uniform] associated with this connection. @expr{localaddr@} and
    //! and @expr{remoteaddr@} include the port, they are therefore not 
    //! necessarily equal to the adresses of the two @[PSYC.Root] objects.
    MMP.Uniform peeraddr, localaddr;

    //! Ip adress of the local- and peerhost of the tcp connection used.
    string peerip, localip;

    function msg_cb, close_cb, get_uniform;
    mapping(function:array) close_cbs = ([ ]); // close_cb == server, close_cbs
					       // contains the callbacks of
					       // the VCs.

    // bytes missing in buf to complete the packet inpacket. (means: inpacket 
    // has _length )
    // start parsing at byte start_parse. start_parse == 0 means create a new
    // packet.
    int m_bytes, start_parse, pcount = 0;

    // cb(received & parsed mmp_message);
    //
    // on close/error:
    // closecb(0); if connections gets closed,
    // 	 --> DISCUSS: closecb(string logmessage); on error? <--
    // 	 maybe: closecb(object dings, void|string error)
    //! @param socket
    //!	    Socket to use. 
    //! @param cb
    //!	    Callback to call for incoming @[MMP.Packet]s. Expected signature is:
    //!	    @expr{void cb(MMP.Packet packet, MMP.Circuit connection);@}
    //! @param close_cb
    //!	    Callback to be called when the @expr{so@} is being closed.
    //!	    Expected signature is: 
    //!	    @expr{void cb(MMP.Circuit connection);@}
    //! @param parse_uni
    //!	    Function to use to parse Uniforms. This is used in @[PSYC.Server] to
    //!	    keep the Uniform cache consistent.
    void create(Stdio.File|Stdio.FILE socket, function cb, function close_cb,
		void|function parse_uni) {
	P2(("MMP.Circuit", "create(%O, %O, %O)\n", so, cb, closecb))
	this_program::socket = socket;
	socket->set_nonblocking(start_read, write, close);
	msg_cb = cb;
	this_program::close_cb = close_cb;
	get_uniform = parse_uni||MMP.parse_uniform;

	localip = (socket->query_address(1) / " ")[0];
	peerip = (socket->query_address() / " ")[0];

	q_neg->push(Packet());
	reset();

	//::create();
    }

    string _sprintf(int type) {
	switch (type) {
	case 's':
	case 'O':
	    return sprintf("MMP.Circuit(%O)", peeraddr);
	}
    }

    void assign(mapping state, string key, mixed val) {
	state[key] = val;	
    }

    void augment(mapping state, string key, mixed val) {
	
	if (arrayp(val)) {
	    foreach (val, string t) {
		augment(state, key, t);
	    }
	} else {
	    // do the same with inpacket->vars too
	    if (arrayp(state[key])) {
		state[key] += ({ val });
	    } else {
		state[key] = ({ state[key], val });
	    }
	}
    }

    void diminish(mapping state, string key, mixed val) {
	if (arrayp(state[key])) {
	    state[key] -= ({ val });
	} else if (has_index(state, key)) {
	    if (state[key] == val)
		m_delete(state, key);
	}
    }


    void reset() {
	lastval = lastkey = lastmod = 0;
	inpacket = Packet(0, copy_value(in_state));
#ifdef LOVE_TELNET
	inpacket->newline = dl;
#endif
    }	

    //! Start actually sending packets.
    //! @note
    //!	    This will be called for you by @[Server].
    void activate() {
	P3(("MMP.Circuit", "%O->activate()\n", this))
	write_okay = 1;
	if (write_ready) write();
    }

    //! Send a negotiation packet. @expr{packet@} will be send even
    //! if the @[Circuit] has not been activated using @[activate()].
    //! @note
    //!	    Use this with care and for negotiation only!
    void send_neg(Packet packet) {
	P3(("MMP.Circuit", "%O->send_neg(%O)\n", this, packet))
	q_neg->push(packet);

	if (write_ready) {
	    write();
	}
    }

    //! Register a packet for sending.
    //! @param holder
    //!	    A @[MMP.Utils.Queue] which holds the @[MMP.Packet] to be sent.
    //! @note
    //!	    Better do @b{not use this directly@}, but use a @[VirtualCircuit]
    //!	    (or something similar you build) to send packets.
    //! @seealso
    //!	    Remember to @[activate()] the Circuit, otherwise no packet
    //!	    will be sent.
    void msg(MMP.Utils.Queue holder) {
	P3(("MMP.Circuit", "%O->msg(%O)\n", this, holder))
	P3(("MMP.Circuit", "%O->msg(%O) where write_ok: %O, write_ready: %O\n", this, sizeof(holder), write_okay, write_ready))
	push(holder);

	if (write_ready) {
	    write();
	}
    }

    int write(void|mixed id) {
	MMP.Utils.Queue currentQ, realQ;
	// we could go for speed with
	// function currentshift, currentunshift;
	// as we'd only have to do the -> lookup for q_neg packages then ,)
	
	if (!write_okay) return (write_ready = 1, 0);

	if (!q_neg->isEmpty()) {
	    currentQ = q_neg;
	    P2(("MMP.Circuit", "Negotiation stuff..\n"))
	} else if (!isEmpty()) {
	    currentQ = this;
	    P2(("MMP.Circuit", "Normal queue...\n"))
	} 
#if DEBUG
	else {
	    P2(("MMP.Circuit", "No packets in queue.\n"))
	}
#endif

	realQ = currentQ;

	if (!currentQ) {
	    write_ready = 1;
	} else {
	    int written;
	    mixed tmp;
	    string s;

	    write_ready = 0;

	    if (currentQ == this) realQ = shift();

	    tmp = realQ->shift();

	    if (arrayp(tmp)) {
		[s, tmp] = tmp;
		// it seems more logical to me, to put all this logic into
		// close.
		if (tmp) (realQ = shift())->shift();
	    } else /* if (objectp(tmp)) */ {
		s = tmp->next();
		if (tmp->has_next()) {
		    realQ->push(tmp);
		    realQ = 0;
		}
		// TODO: HOOK
	    }

	    // TODO: encode
	    //s = trigger("encode", s);
	    written = socket->write(s);

	    P2(("MMP.Circuit", "%O wrote (%O) %d (of %d) bytes.\n", this, s, written, 
		sizeof(s)))

	    if (written != sizeof(s)) {
		if (realQ) {
		    q_neg->unshift(({ s[written..], tmp }));
		    unshift(realQ);
		    realQ->unshift(tmp);	
		} else {
		    q_neg->unshift(({ s[written..], 0 }));
		}
	    } else {
		if (tmp->sent)
		    tmp->sent();
	    }
	}

	return 1;
    }

    int start_read(mixed id, string data) {

	// is there anyone who would send \n\r ???
#ifdef LOVE_TELNET
	if (data[0 .. 2] == ".\n\r") {
	    dl = "\n\r";
	} else if (data[0 .. 2] == ".\r\n") {
	    dl = "\r\n";
	} else 
#endif
	if (data[0 .. 1] != ".\n") {
	    // TODO: error message
	    socket->close();
	    close(0);
	    return 1;
	}

	// the reset has been called before.
#ifdef LOVE_TELNET
	inpacket->newline = dl;
#endif
	P2(("MMP.Circuit", "%s sent a proper initialisation packet.\n", 
	    peeraddr))
#ifdef LOVE_TELNET
	if (sizeof(data) > ((dl) ? 3 : 2)) {
	    read(0, data[((dl) ? 3 : 2) ..]);
	}
#else 
	if (sizeof(data) > 2) {
	    read(0, data[2 ..]);
	}
#endif
	socket->set_read_callback(read);
    }

    int read(mixed id, string data) {
	int ret = 0;
	// TODO: decode

	P2(("MMP.Circuit", "read %d bytes.\n", sizeof(data)))

	if (!inbuf)
	    inbuf = data;
	else if (stringp(inbuf)) {
	    if (m_bytes && 0 < (m_bytes -= sizeof(data))) {
		// create a String.Buffer
		String.Buffer t = String.Buffer(sizeof(inbuf)+m_bytes);
		t += inbuf;
		t += data;
		inbuf = t;
		// dont try to parse again
		return 1;
	    }
	    inbuf += data;
	} else {
	    m_bytes -= sizeof(data);
	    inbuf += data;
	    if (0 < m_bytes) return 1;

	    // create a string since we will try to parse..
	    inbuf = inbuf->get();
	}

	array(mixed) exception = catch {
	    while (inbuf && !(ret = 
#ifdef LOVE_TELNET
		    (dl) ? parse(dl) :
#endif
				     parse())) {

		P2(("MMP.Circuit", "parsed %O.\n", inpacket))
		if (inpacket->data) {
		    // TODO: HOOK
		    if (inpacket->parsed)
			inpacket->parsed();
		    if (objectp(inpacket["_target"])) {
			if (pcount < 3) {
			    if (!inpacket["_target"]->reconnectable) inpacket["_target"]->islocal = 1;
			}
		    }
		    msg_cb(inpacket, this);
		    reset(); // watch out. this may produce strange bugs...
		} else {
		    P2(("MMP.Circuit", "Got a ping.\n"))
		}
		pcount++;
	    }
	    if (ret > 0) m_bytes = ret;
	};

	if (exception) {
	    if (objectp(exception)
		&& Program.inherits(object_program(exception), Error.Generic)) {
		P0(("MMP.Circuit", "Caught an error: %O, %O\n", exception,
		    exception->backtrace()))
	    } else {
		P0(("MMP.Circuit", "Catched an error: %O\n", exception))
	    }
	    // TODO: error message
	    socket->close();
	    close(0);
	}


	return 1;	
    }

    int close(mixed id) {
	P0(("MMP.Circuit", "%O: Connection closed.\n", this))
	// TODO: error message
	close_cb(this);

	foreach (close_cbs; function cb; array args) {
	    cb(@args);
	}
    }

    // works quite similar to the psyc-parser. we may think about sharing some
    // source-code. 
    //! @ignore
#define RETURN(x)	ret = (x); stop = -1
#define INBUF	((string)inbuf)
#ifdef LOVE_TELNET
# define LL	sizeof(linebreak)
# define LD	linebreak
    int parse(void|string linebreak) {

	if (!linebreak) linebreak = "\n";
#else
    int parse() {
# define LL	1
# define LD	"\n"
#endif

	string key, val;
	int mod, start, stop, num, ret;

	ret = -1;

	// expects to be called only if inbuf is nonempty
    
	P2(("MMP.Parse", "parsing: %d from position %d\n", sizeof(inbuf), 
	    start_parse))
LINE:	while(-1 < stop && 
	      -1 < (stop = (start = (mod) ? stop+LL : start_parse, 
			    search(inbuf, LD, start)))) {
	    mod = INBUF[start];
	    P2(("MMP.Parse", "start: %d, stop: %d. mod: %c\n", start,stop,mod))
	    P2(("MMP.Parse", "parsing line: '%s'\n", INBUF[start .. stop-1]))
	    // check for an empty line.. start == stop
	    if (stop > start) switch(mod) {
	    case '.':
		// empty packet. should be accepted in any case.. 
		//
		// it may be wrong to make a difference between packets without
		// newline as delimiter.. and those with and without data..
		inpacket->data = 0;
		inbuf = INBUF[stop+LL .. ];
		RETURN(0);
		break;
	    case '?':
		THROW("modifier '?' not supported, yet.");
	    case '-':
	    case '+':
	    case '=':
	    case ':':
#ifdef LOVE_TELNET
		num = sscanf(INBUF[start+1 .. stop-1], "%[A-Za-z_]%*[\t ]%s",
			     key, val);
#else
		num = sscanf(INBUF[start+1 .. stop-1], "%[A-Za-z_]\t%s",
			     key, val);
#endif
		if (num == 0) THROW("parsing error");
		// this is either an empty string or a delete. we have to decide
		// on that.
		
		start_parse = stop+LL;
		P2(("MMP.Parse", "%s => %O \n", key, val))

		if (num == 1) {
		    val = UNDEFINED; // undefined is zero_type != 0 and becomes
				     // an empty variable again. 
		} else {
		    string k = (key == "") ? lastkey : key;		    

		    if (k != "") {
			int n = search(k, '_', 1);

			switch (n == -1 ? k : k[0..n-1]) {
			case "_source":
			case "_target":
			case "_context":
			    P3(("MMP.Circuit", "cb: %O\n", get_uniform))
			    val = get_uniform(val); 
			}
    
		    }
		    if (key == "") {
			if (mod != lastmod) THROW("improper list continuation");
			if (mod == '-') 
			    THROW( "diminishing lists is not supported");
			if (!arrayp(lastval)) {
			    lastval = ({ lastval, val });
			} else {
			    lastval += ({ val });
			}
			continue LINE;
		    }
		}
		break;
	    case '\t':
		if (!lastmod) THROW( "invalid variable continuation");
		P2(("MMP.Parse", "mmp-parse: + %s\n", INBUF[start+1 .. stop-1]))
		if (arrayp(lastval))
		    lastval[-1] += "\n" +INBUF[start+1 .. stop-1];
		else
		    lastval += "\n" +INBUF[start+1 .. stop-1];

		start_parse = stop+LL;
		continue LINE;
	    default:
		THROW("unknown modifier "+String.int2char(mod));

	    } else {
		// this else is an empty line.. 
		// allow for different line-delimiters
		int length = inpacket["_length"];

		if (length) {
		    if (stop+LL + length > sizeof(inbuf)) {
			start_parse = start;
			P2(("MMP.Parse", 
			    "reached the data-part. %d bytes missing (_length "
			    "specified)\n", stop+LL+length-sizeof(inbuf)))
			RETURN(stop+LL+length-sizeof(inbuf));
		    } else {
			// TODO: we have to check if the packet-delimiter
			// is _really_ there. and throw otherwise
			inpacket->data = INBUF[stop+LL .. stop+LL+length];
			if (sizeof(inbuf) == stop+3*LL+length+1)
			    inbuf = 0;
			else
			    inbuf = INBUF[stop+length+3*LL+1 .. ];
			start_parse = 0;
			P2(("MMP.Parse", "reached the data-part. finished. "
			    "(_length specified)\n"))
			RETURN(0);
		    }
		    // TODO: we could cache the last sizeof(inbuf) for failed
		    // searches.. 
		} else if (-1 == (length = search(inbuf, LD+"."+LD, stop+LL))) {
		    start_parse = start;
		    P2(("MMP.Parse", "reached the data-part. i dont know how "
			"much is missing.\n"))
		    RETURN(-1);
		} else {
		    inpacket->data = INBUF[stop+LL .. length-1];	
		    P2(("MMP.Server", "data: %O\n", inpacket->data))
		    if (sizeof(inbuf) == length+2*LL+1)
			inbuf = 0;
		    else
			inbuf = INBUF[length+2*LL+1 .. ];
		    start_parse = 0;
		    P2(("MMP.Parse", "reached the data-part. finished.\n"))
		    RETURN(0);
		}
	    }

	    if (lastkey) {
		switch (lastmod) {
		case '=':
		    in_state[lastkey] = lastval;
		case ':':
		    inpacket[lastkey] = lastval;
		    break;
		case '+':
		    augment(in_state, lastkey, lastval);
		    augment(inpacket->vars, lastkey, lastval);
		    break;
		case '-':
		    diminish(in_state, lastkey, lastval);
		    diminish(inpacket->vars, lastkey, lastval);
		    break;
		}
	    }

	    lastmod = mod;
	    lastkey = key;
	    lastval = val;

	}

	return ret;
    }
    //! @endignore

    void add_close_cb(function cb, mixed ... args) {
	close_cbs[cb] = args;
    }

    void remove_close_cb(function cb) {
	m_delete(close_cbs, cb);
    }
}
#undef INBUF
#undef RETURN
#undef LL
#undef LD

//! A @[Circuit] that is active (i.e. an outgoing connection).
class Active {
    inherit Circuit;

    void create(Stdio.File|Stdio.FILE so, function cb, function closecb, void|function get_uniform) {
	::create(so, cb, closecb, get_uniform);

	string peerhost = so->query_address(1);
	localaddr = get_uniform("psyc://"+((peerhost / " ") * ":-"));
	localaddr->islocal = 1;
	peerhost = so->query_address();
	peeraddr = get_uniform("psyc://"+((peerhost / " ") * ":"));
	peeraddr->islocal = 0;
	//peeraddr->handler = this;
    }

    //void start_read(mixed id, string data) {
    //	::start_read(id, data);
    //}
}

//! A @[Circuit] that is passive (i.e. an inbound connection). Use this for 
//! already @[Stdio.Port()->accept()]ed sockets (sockets ready to transport
//! MMP).
class Server {
    inherit Circuit;

    void create(Stdio.File|Stdio.FILE so, function cb, function closecb, void|function get_uniform) {
	::create(so, cb, closecb, get_uniform);

	string peerhost = so->query_address(1);
	localaddr = get_uniform("psyc://"+((peerhost / " ") * ":"));
	localaddr->islocal = 1;
	peerhost = so->query_address();
	peeraddr = get_uniform("psyc://"+((peerhost / " ") * ":-"));
	peeraddr->islocal = 0;

	activate();
    }

    int sgn() {
	return -1;
    }

    //! @ignore
#ifdef LOVE_TELNET
    int parse(void|string ld) {
	int ret = ::parse(ld);
#else
    int parse() {
	int ret = ::parse();
#endif

	if (ret == 0) {
	    if (inpacket->data == 0 && !sizeof(inpacket->vars)) {
		send_neg(Packet());
	    }
	}

	return ret;
    }
    //! @endignore
}


//! This is an intermediate object which tries to keep a @[Circuit] to a certain
//! target open. Multiple of this adapters may share the same @[Circuit].
//! However, if a @[Circuit] breaks and can't be reestablished, adapters that 
//! once shared a @[Circuit] may end up in using different ones (potentially 
//! to different servers).
//! 
//! Supports SRV records in domain resolution.
class VirtualCircuit {
    inherit MMP.Utils.Queue; // me hulk! me can queue!

    MMP.Circuit circuit;
    MMP.Utils.DNS.SRVReply cres;
    object server; // duh. pike really needs a way to solve "recursive"
		   // dependencies.
    function check_out, failure_delivery;
    // following two will be needed when a circuit breaks and can't be
    // reestablished
    string targethost;
    int targetport, dead = 0;
    MMP.Uniform peer;

    string _sprinf(int type) {
	if (type == 's' || type == 'O') {
	    return sprintf("MMP.VirtualCircuit(%s:%d)", targethost, targetport);
	}
    }

    //! @param peer
    //!	    Uniform of the peer to connect to. If the port is omitted service 
    //!	    discovery is done using SRV Records.
    //! @param server
    //!	    @[PSYC.Server] or similar object, which offers
    //!	    @ul
    //!		@item
    //!		    @expr{void connect_to(MMP.Uniform to_root, function(MMP.Circuit : void) cb);@}
    //!		@item
    //!		    @expr{MMP.Uniform get_uniform(string uniform);@}
    //!
    //!		    (See @[PSYC.Server()->get_uniform()]).
    //!	    @endul
    //! @param error
    //!     Callback to be called for packets that could not be delivered successfully.
    //! @param check_out
    //!	    A callback the @[VirtualCircuit] calls to check out from the server.
    //!	    Currently unused.
    //! @param c
    //!	    If a suiting @[Circuit] should be at hand, pass this as @expr{c@}.
    //!	    No resolving and/or connection action will then be taken until @expr{c@}
    //!	    "breaks".
    void create(MMP.Uniform peer, object server, function|void error, 
		function|void check_out, MMP.Circuit|void c) {
	P2(("VirtualCircuit", "create(%O, %O, %O)\n", _peer, srv, c))

	this_program::peer = peer;
	targethost = peer->host;
	targetport = peer->port;

	this_program::server = server;
	this_program::check_out = check_out;
	failure_delivery = error;

	if (!c) {
	    init();
	} else {
	    on_connect(c);
	}
    }

    void init() {
	int port = targetport;
	if (MMP.Utils.Net.is_ip(targethost) && !port) port = 4404;

	if (port) {
	    connect_host(targethost, port);
	} else {
	    connect_srv();
	}
    }

    void on_close() {
	circuit = 0;
	init();
    }

    void on_connect(MMP.Circuit c) {
	if (c) {
	    int sof = _sizeof();
	    circuit = c;
	    destruct(cres);

	    // so we will get notified when the connection can't be
	    // maintained any longer (connection break, reconnect fails)
	    circuit->add_close_cb(on_close);

	    for (int i = 0; i < sof; i++) {
		circuit->msg(this);
	    }
	} else {
	    if (cres) {
		srv_step();
	    } else {
		error_unroll();
		// this error is here to catch the port < 0 case.

		// TODO:: try alternatives (srv, multiple a rr), eventually
		// error. move error_unroll to the end.
	    }
	}
    }

    void connect_ip(string ip, int port) {
	server->circuit_to(peer, on_connect);
    }

    void connect_host(string host, int port) {
	void dispatch(string query, string ip) {
	    if (ip) {
		connect_ip(ip, port);
	    } else {
		// TODO:: error
		error_unroll();
	    }
	};

	if (MMP.Utils.Net.is_ip(host)) {
	    connect_ip(host, port);
	} else {
	    // TODO:: resolve in a way that gives us multiple records.
	    Protocols.DNS.async_host_to_ip(host, dispatch);
	}
    }

    void destroy() { // just in case... dunno when the maintenance in here
		     // is neccessary. probably never, but doesn't hurt much.
	circuit->remove_close_cb(on_close);
    }

    void srv_step() {
	if (cres->has_next()) {
	    mapping m = cres->next();

	    connect_host(m->target, m->port);
	} else {
	    destruct(cres);

	    error_unroll();
	    // TODO:: there was at least one srv-host, not reachable, so we
	    // can't reach the target and therefore need to error!
	}
    }

    void connect_srv() {
	void srvcb(string query, MMP.Utils.DNS.SRVReply|int result) {
	    P3(("VirtualCircuit", "srvcb(%O, %O)\n", query, result))
	    if (objectp(result)) {
		if (result->has_next()) {
		    if (has_value(result->result->target, ".")) {
			// no psyc offered. error all queued packages, error
			// and destruct.
		    } else {
			cres = result;
			srv_step();
		    }
		} else {
		    connect_host(targethost, 4404);
		}
	    }
	};

	MMP.Utils.DNS.async_srv("psyc-server", "tcp", targethost, srvcb);
    }

    void error_unroll() {
	dead = 1;
	while (sizeof(this)) {
	    MMP.Packet p = shift();

	    failure_delivery(p["_target"] || peer, p);
	}
    }

    //! Sends a @[Packet] to this @[VirtualCircuit]'s target.
    //! If delivery fails, eventually opening new circuits to other
    //! (responsible) servers will be opened.
    void msg(MMP.Packet p) {
	P2(("VirtualCircuit", "%O->msg(%O)\n", peer, p))
	if (dead) {
	    failure_delivery(p["_target"] || peer, p);
	    return;
	}
	push(p);

	if (circuit) circuit->msg(this);
    }
}

//! @returns
//! @int
//! 	@value 1
//! 		@expr{o@} is a @[Uniform].
//! 	@value 0
//! 		@expr{o@} is not a @[Uniform].
//! @endint
int(0..1) is_uniform(mixed o) {
    if (objectp(o) && Program.inherits(object_program(o), Uniform)) {
	return 1;
    } else {
	return 0;
    }
}

//! @returns
//! @int
//! 	@value 1
//! 		@expr{o@} is a MMP.Uniform designated by @expr{designator@}
//! 	@value 0
//! 		@expr{o@} is not a Person.
//! @endint
//!
//! @seealso
//!	@[is_person()], @[is_place()], @[is_uniform()]
int(0..1) is_thing(mixed o, int designator) {
    return is_uniform(o) && stringp(o->resource) && sizeof(o->resource) && o->resource[0] == designator;
}

//! @returns
//! @int
//! 	@value 1
//! 		@expr{o@} is a Person (designated by an '~' in MMP/PSYC).
//! 	@value 0
//! 		@expr{o@} is not a Person.
//! @endint
//!
//! @seealso
//!	@[is_thing()], @[is_place()], @[is_uniform()]
int(0..1) is_person(mixed o) {
    return is_thing(o, '~');
}

//! @returns
//! @int
//! 	@value 1
//! 		@expr{o@} is a Place (designated by an '@@' in MMP/PSYC).
//! 	@value 0
//! 		@expr{o@} is not a Place.
//! @endint
//! @seealso
//!	@[is_thing()], @[is_person()], @[is_uniform()]
int(0..1) is_place(mixed o) {
    return is_thing(o, '@');
}
