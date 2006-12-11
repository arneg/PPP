// vim:syntax=lpc
// put that somewhere else.. maybe
//
#include <debug.h>

class Dummy(mixed...params) { }

Packet reply(Packet m, string|void mc, string|void data, mapping(string:mixed)|void vars) {
    Packet t = Packet(mc, data, vars);

    if (has_index(m->vars, "_tag"))
	t->vars["_tag_reply"] = m->vars["_tag"];

    return t;
}

class Packet {
    string mc, cache;
    mapping (string:mixed) vars;
    string data;

    void create(string|void m, mapping(string:mixed)|void v, string|void d) {
	if (m) mc = m;
	data = d || "";
	vars = v || ([ ]);
    }

    mixed cast(string type) {
	switch(type) {
	case "string":
	    return cache || (cache = .module.render(this_object()));
	case "String.Buffer":
	    return String.Buffer() + (string)this;
	default:
	    return UNDEFINED;
	}
    }

    string _sprintf(int format) {
	switch (format) {
	    case 'O':
#if defined(DEBUG) && DEBUG < 3
		return sprintf("PSYC.Packet(%O, %O)", mc, vars);
#else
		return sprintf("PSYC.Packet(%O)", mc);
#endif
	    case 's':
		return (string)this;
	}
    }

    PSYC.Packet reply(string|void mc, mapping(string:mixed)|void v, string|void d) {
	PSYC.Packet m = PSYC.Packet(mc, v, d);

	if (has_index(vars, "_tag") && sizeof(vars["_tag"])) {
	    m["_tag_reply"] = vars["_tag"]; 
	}

	return m;
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
	return vars[id];
    }
}

// this is an intermediate object which tries to keep a circuit to a certain
// target open.
// multiple of this adapters may share the same circuit.
// however, if a circuit breaks and can't be reestablished, 
// adapters that once shared a circuit may end up in using different circuits
// (to different servers).
class Adapter { // TODO:: change that name!!
    MMP.Utils.Queue q;
    MMP.Circuit circuit;
    MMP.Utils.DNS.SRVReply cres;
    PSYC.Server server;
    function check_out;
    // following to will be needed when a circuit breaks and can't be
    // reestablished
    string targethost;
    int targetport;

    void create(MMP.Uniform target, PSYC.Server srv, function co) {
	targethost = target->host;
	targetport = target->port;

	server = srv;
	check_out = co;

	init();
    }

    void init() {
	int port = targetport;
	if (MMP.Utils.Net.is_ip(targethost) && !port) port = 4404;

	if (port) {
	    connect_host(targethost, port);
	} else {
	    connect_srv(targethost);
	}
    }

    void on_connect(MMP.Circuit c) {
	if (c) {
	    circuit = c;

	    if (q) {
		destruct(cres);
		// very temporary solution. we'll need to maintain our own queue
		// and only advertise msg-requests to the circuit, which will
		// then shift the messages here.
		while (!q->isEmpty()) {
		    c->msg(q->shift());
		}

		destruct(q);
	    }
	} else {
	    if (cres) {
		srv_step();
	    } else {
		// TODO:: try alternatives (srv, multiple a rr), eventually
		// error.
	    }
	}
    }


    void connect_ip(string ip, int port) {
	server->circuit_to(ip, port, on_connect);
    }

    void connect_host(string host, int port) {
	void dispatch(string query, string ip) {
	    if (ip) {
		connect_ip(ip, port);
	    } else {
		// TODO:: error
	    }
	};

	if (MMP.Utils.Net.is_ip(host)) {
	    connect_ip(host, port);
	} else {
	    // TODO:: resolve in a way that gives us multiple records.
	    Protocols.DNS.async_host_to_ip(host, dispatch);
	}
    }

    void srv_step() {
	if (cres->has_next()) {
	    mapping m = cres->next();

	    connect_host(m->target, m->port);
	} else {
	    destruct(cres);
	    // TODO:: there was at least one srv-host, not reachable, so we
	    // can't reach the target and therefore need to error!
	}
    }

    void connect_srv(string host) {
	void srvcb(string query, MMP.Utils.DNS.SRVReply|int result) {
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
		    connect_host(host, 4404);
		}
	    }
	};

	MMP.Utils.DNS.async_srv("psyc-server", "tcp", host, srvcb);
    }
}

#if 0
// evil parser
string psyctext(PSYC.Packet m) {
    String.Buffer buf = String.Buffer(); 

    string data = m->data;
    
    int opened;
    int start, stop;

    while (stop < sizeof(data)-1) {
	start = stop;
	if (opened) {
	    stop = search(data, "]", start);
	} else {
	    stop = search(data, "[", start);
	}

	if (stop == -1 || sizeof(data)-1 <= stop+1) {
	    buf->add(data[start..]);
	    break;
	}

	if (opened && data[start+1] == '_' 
	&& has_index(m->vars, data[start+1..stop-1])) {
	    buf->add(m->vars[data[start+1..stop-1]]);
	} else {
	    buf->add(data[start..stop]);
	}

	opened ^= 1;
    }

    return buf->get();
}
#endif

string psyctext(MMP.Packet p, PSYC.Text.TextDB db) {
    mapping v;
    string tmp;
    int is_message;

    if (equal(p->data->mc / "_", ({ "", "message" }))) {
	is_message = 1;
    }

    if (p->vars) {
	v = ([]);
	v += p->vars;
    }

    if (p->data && p->data->vars) {
	if (!v) v = ([]);
	v += p->data->vars;
    }

    if (is_message && p->data->data) {
	if (!v) v = ([]);
	v["_data"] = p->data->data;
    }

    tmp = db[p->data->mc] || (is_message ? "[_data]" : p->data->data);

    if (v && tmp) {
	return PSYC.Text.psyctext(tmp, v);
    }

    return tmp || p->data->mc;
}

string|String.Buffer render(Packet o, void|String.Buffer to) {
    String.Buffer p;

    // this could be used to render several psyc-packets/mmp-packets at once
    // into one huge string. should give some decent optimiziation
    if (to)
	p = to;	
    else 
	p = String.Buffer();

    function add = p->add;
    function putchar = p->putchar;

    if (sizeof(o->vars)) 
#if LOVE_JSON
    foreach (o->vars; string key; mixed value) {
	string mod;
	if (key[0] == '_') {
	    mod = ":";
	} else {
	    mod = key[0..0];
	    key = key[1..];
	}

	putchar(mod[0]);
	add(key);
	putchar('\t');
	JSON.serialize(value, p, "\n"+mod+"\t");
	add("\n");
    }
#else
    MMP.render_vars(o->vars, p); 
#endif

    add(o->mc);
    putchar('\n');
    if (o->data) add(o->data);

    if (to) return p; 
    return p->get();
}

// returns a Packet or an error string
#ifdef LOVE_TELNET
Packet parse(string data, string|void linebreak) {
    if (linebreak == 0) linebreak = "\n";
# define LL	linebreak
# define LD	sizeof(linebreak)
#else
Packet parse(string data) {
# define LL	"\n"
# define LD	1
#endif
    int start, stop, num, lastmod, mod;
    string key, lastkey; 
    mixed lastval, val;

    Packet packet = Packet();
    packet->vars = ([]);
    packet->cache = data;

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
	    num = sscanf(data[start+1 .. stop-1], "%[A-Za-z_]"
#ifdef LOVE_TELNET
			 "%*[ \t]"
#else
			 "\t"
#endif
			 "%s", key, val);
	    P2(("PSYC.parse", "parsed variable: %s => %O\n", key, val))
	    if (num == 0) THROW("Blub");
	    if (num == 1) val = UNDEFINED;
	    else if (key == "") { // list continuation
#ifdef LOVE_JSON
		if (mod != lastmod) 
		    THROW("improper list continuation");
		if (mod == '-') THROW("diminishing lists is not supported");
		if (stringp(lastval) || intp(lastval)) 
		    lastval = ({ lastval, val });
		else lastval += ({ val });
		continue LINE;
#else
		THROW("Using JSON for lists from now on!");
#endif 
	    }
	    
	    break;
	case '\t': // variable continuation
	    if (!lastmod) THROW("invalid variable continuation");
	    P2(("PSYC.parse", "parsed variable continuation: %s\n", 
		data[start+1 .. stop]))
	    if (arrayp(lastval))
		lastval[-1] += "\n" + data[start+1 .. stop-1];
	    else 
		lastval += "\n" + data[start+1 .. stop-1];
	    continue LINE;
	case '_':
	    // TODO: check mc for sanity
	    packet->mc = data[start .. stop-1];
	    if (strlen(data) > stop+LD)
		data = data[stop+LD ..];
	    else data = "";
	    P2(("PSYC.parse", "parsed method: %s\n", packet->mc))
	    stop = -1;
	    break;
	default:
	    THROW("Unknown variable modifier: " + mod);
	}

	// TODO: modifier unterscheiden
	if (lastmod != 0) {
#ifdef LOVE_JSON
	    // long term plan is to make that on demand inside the packet..
	    if (stringp(lastval))
		lastval = JSON.parse(lastval);
#endif
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

