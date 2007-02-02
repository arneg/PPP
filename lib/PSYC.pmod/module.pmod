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

int abbrev(string haystack, string needle) {
    if (haystack == needle) return 1;

    if (sizeof(needle) < sizeof(haystack)) return 0;

    if (haystack[..sizeof(needle)-1] != needle) return 0;

    if (haystack[sizeof(needle)] == '_') return 1;

    return 0;
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
#if defined(DEBUG) && DEBUG > 3
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
Packet parse(string data, function parse_JSON, string|void linebreak, object|void packet) {
    if (linebreak == 0) linebreak = "\n";
# define LL	linebreak
# define LD	sizeof(linebreak)
#else
Packet parse(string data, function parse_JSON, object|void packet) {
# define LL	"\n"
# define LD	1
#endif
    int start, stop, num, lastmod, mod;
    string key, lastkey; 
    mixed lastval, val;

    if (!packet) packet = Packet();
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
		lastval = parse_JSON(lastval);
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

