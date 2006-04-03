// put that somewhere else.. maybe
//
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
    if (!sscanf(t, "%s:%s", u->scheme, t)) return 0;
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
	    if (num == 0) return "Blub";
	    if (num == 1) val = 0;
	    else if (key == "") { // list continuation
		if (mod != lastmod) return "improper list continuation";
		if (mod == '-') return "diminishing lists is not supported";
		if (stringp(lastval) || intp(lastval)) 
		    lastval = ({ lastval, val });
		else lastval += ({ val });
		continue LINE;
	    }
	    
	    break;
	case '\t': // variable continuation
	    if (!lastmod) return "invalid variable continuation";
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
	    return "Unknown variable modifier: " + mod;
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
	} else return "Method is missing.";
    } else packet->data = data;  

    return packet;
}

