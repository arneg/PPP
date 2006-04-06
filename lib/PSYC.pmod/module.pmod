// vim:syntax=lpc
// put that somewhere else.. maybe
//
#define THROW(s)	throw(({ (s), backtrace() }))
class uniform {
    string scheme, transport, host, user, resource, slashes, query, body,
	   userAtHost, pass, hostPort, circuit, root, unl;
    int port;

    mixed cast(string type) {
	if (type == "string") return unl;
    }
}

uniform parse_uniform(string s) {
    string t;
    uniform u = uniform();

    u->unl = s;
    t = s;
    if (!sscanf(t, "%s:%s", u->scheme, t)) THROW("this is not uniforminess");
    u->slashes = "";
    switch(u->scheme) {
    case "sip":
	    sscanf(t, "%s;%s", t, u->query);
	    break;
    case "xmpp":
    case "mailto":
	    sscanf(t, "%s?%s", t, u->query);
    case "telnet":
	    break;
    default:
	    if (t[0..2] == "//") {
		    t = t[2..];
		    u->slashes = "//";
	    }
    }
    u->body = t;
    sscanf(t, "%s/%s", t, u->resource);
    u->userAtHost = t;
    if (sscanf(t, "%s@%s", s, t)) {
	    if (!sscanf(s, "%s:%s", u->user, u->pass))
		u->user = s;
    }
    u->hostPort = t;
    //if (complete) u->circuit = u->scheme+":"+u->hostPort;
    u->root = u->scheme+":"+u->slashes+u->hostPort;
    if (sscanf(t, "%s:%s", t, s)) {
	    if (!sscanf(s, "%d%s", u->port, u->transport))
		u->transport = s;
    }
    u->host = t;
    return u;
}

class psyc_p {
    string mc, cache;
    mapping (string:mixed) vars;
    mixed data;

    void create(string|void m, string|void d, 
		mapping(string:mixed)|void v ) {
	mc = m;
	data = d||"";
	vars = v||([]);
    }

    mixed cast(string type) {
	switch(type) {
	case "string":
	    return cache || (cache = render(this_object()));
	case "String.Buffer":
	    return String.Buffer() + (cache || render(this));
	default:
	    return 0;
	}
    }

    string _sprintf(int format) {
	switch (format) {
	    case 'O':
		return sprintf("PSYC.psyc_p(%O)", mc);
	    case 's':
		return (string)this;
	}
    }

    mixed `[]=(mixed id, mixed val) {
	cache = UNDEFINED;
	return vars[id] = val;
    }

    mixed `->=(string id, mixed val) {
	cache = UNDEFINED;

	return ::`->=(id, val);
    }

    mixed `[](mixed id) {
	if (has_index(vars, id)) return vars[id];

	return UNDEFINED;
    }
}

string|String.Buffer render(psyc_p o, void|String.Buffer to) {
    string key, mod;
    mixed temp;
    String.Buffer p;

    // this could be used to render several psyc-packets/mmp-packets at once
    // into one huge string. should give some decent optimiziation
    if (to)
	p = to;	
    else 
	p = String.Buffer();

    function add = p->add;
    function putchar = p->putchar;


    if (mappingp(o->vars)) foreach (indices(o->vars), key) {

	if (key[0] == '_') mod = ":";
	else mod = key[0..0];
	
	temp = o->vars[key];

	// we have to decide between deletions.. and "".. or 0.. or it
	// a int zero not allowed?
	if (temp) {
	    if (key[0] == '_') putchar(':');
	    add(key);
	    putchar('\t');
	    
	    if (stringp(temp))
		add(replace(temp, "\n", "\n\t")); 
	    else if (arrayp(temp))
		add(map(temp, replace, "\n", "\n\t") * ("\n"+mod+"\t"));
	    else if (mappingp(temp))
		add("dummy");
	    else if (intp(temp))
		add((string)temp);
	    
	    putchar('\n');
	
	} else {
	    if (key[0] == '_') putchar(':');
	    add(key);
	    putchar('\n');
	}
    }

    add(o->mc);
    putchar('\n');
    if (o->data) add(o->data);

    if (to) return p; 
    return p->get();
}

// returns a psyc_p or an error string
#ifdef LOVE_TELNET
psyc_p|string parse(string data, string|void linebreak) {
    if (linebreak == 0) linebreak = "\n";
#define LL	linebreak
#define LD	sizeof(linebreak)
#else
psyc_p|string parse(string data) {
#define LL	"\n"
#define LD	1
#endif
    int start, stop, num, lastmod, mod;
    string key, lastkey; 
    mixed lastval, val;

    psyc_p packet = psyc_p();
    packet->vars = ([]);

// may look kinda strange, but i use continue as a goto ,)
// .. also a < is not expensive at all. this could be an != actually...
LINE:while (-1 < stop &&
	    -1 < (stop = (start= (lastmod) ? stop+LD : 0, 
		  search(data, LL, start)))) {

	
	// check for an empty line.. start == stop
	mod = data[start];
	switch(mod) {
	case '=':
	case '+':
	case '-':
	case '?': // not implemented yet.. 
	case ':':
	    num = sscanf(data[start+1 .. stop-1], "%[A-Za-z_]\t%s", key, val);
	    write("psyc-parse: "+key+" => "+val+"\n");
	    if (num == 0) THROW("Blub");
	    if (num == 1) val = 0;
	    else if (key == "") { // list continuation
		if (mod != lastmod) 
		    THROW("improper list continuation");
		if (mod == '-') THROW("diminishing lists is not supported");
		if (stringp(lastval) || intp(lastval)) 
		    lastval = ({ lastval, val });
		else lastval += ({ val });
		continue LINE;
	    }
	    
	    break;
	case '\t': // variable continuation
	    if (!lastmod) THROW("invalid variable continuation");
	    write("psyc-parse:\t+ "+data[start+1 .. stop]);
	    if (arrayp(lastval))
		lastval[-1] += "\n" + data[start+1 .. stop-1];
	    else 
		lastval += "\n" + data[start+1 .. stop-1];
	    continue LINE;
	case '_':
	    // TODO: check mc for sanity
	    packet->mc = data[start .. stop-1];
	    if (strlen(data) > stop+1)
		data = data[stop+1 ..];
	    else data = "";
	    write("mc: "+ packet->mc + "\n");
	    stop = -1;
	    break;
	default:
	    THROW("Unknown variable modifier: " + mod);
	}

	// TODO: modifier unterscheiden
	if (lastmod != 0) {
	    if (lastmod != ':') lastkey = String.int2char(lastmod) + lastkey;
	    packet->vars += ([ lastkey : lastval ]);
	}
	lastmod = mod;
	lastkey = key;
	lastval = val;
    }

    // in case the packet contains 0 data
    if (packet->mc == 0) {
	if (strlen(data) > 1 && data[0] == '_') { 
	    packet->mc = data;
	    packet->data = "";
	} else THROW("Method is missing.");
    } else packet->data = data;  

    return packet;
}

class Server {
    mapping(string:mixed) localhosts;
    mapping(string:object) targets = ([ ]), 
			   contexts = ([ ]), 
			   connections = ([ ]);
    function create_local, create_remote;
    
    void create(mapping(string:mixed) config) {

	// looks terribly ugly..
	if (has_index(config, "localhosts")) { 
	    localhosts = config["localhosts"];
	} else {
	    localhosts = ([ ]);
	}
	localhosts += ([ 
			"localhost" : 1,
			"127.0.0.1" : 1,
		      ]);

	if (has_index(config, "create_local")) {
	    create_local = config["create_local"];
	} else {
	    throw("urks");
	}

	if (has_index(config, "create_remote")) {
	    create_local = config["create_remote"];
	} else {
	    throw("urks");
	}

	if (has_index(config, "ports")) {
	    // more error-checking would be a good idea.
	    int|string port;
	    string ip;
	    Stdio.Port p;
	    foreach (port, config["ports"]) {
		if (intp(port)) {
		    p = Stdio.Port(port, accept);
		} else { // is a string
		    (ip, port) = port / ":";
		    p = Stdio.Port(port, accept, ip);
		    localhosts[ip] = 1;
		}
		p->set_id(p);
	    }
	} else throw("help!");
    }

    void accept(Stdio.Port _) {
	string peerhost;
	Stdio.File __;
	write("%O\n", _);
	__ = _->accept();
	peerhost = __->query_address();

	connections[peerhost] = MMP.Circuit(__, deliver, close);
    }

    void close(MMP.Circuit c) {
	MMP.mmp_p p;

	m_delete(connections, c->socket->peerhost);
	
	while (!c->isEmpty()) {
	    p = c->shift();
	    deliver(p);
	}
    }

    void if_localhost(string host, function if_cb, function else_cb, 
		      mixed ... args ) {
	// this is rather blöde
	void callback(string ip, function if_cb, function else_cb, 
		      mixed ... args ) {
	    if (has_index(localhosts, ip))
		if_cb(args);
	    else
		else_cb(args);
		
	}
	if (has_index(localhosts, host)) {
	    if_cb(args);
	} else if (sscanf(host, "%*d:%*d:%*d:%*d") == 4) {
	    Protocols.DNS.async_ip_to_host(host, callback, if_cb, else_cb, 
					   args);
	} else {
	    Protocols.DNS.async_host_to_ip(host, callback, if_cb, else_cb, 
					   args);
	}
    }

    void unicast(string target, string source, PSYC.psyc_p packet) {
	MMP.mmp_p mpacket = MMP.mmp_p(packet, 
				      ([ "_source" : source,
					 "_target" : target ]);
    }

    void register_uniform(string uni, object o) {
	targets[uni] = o;
    }

    void unregister_uniform(string uni) {
	m_delete(targets, uni);
    }
}
