// vim:syntax=lpc
// put that somewhere else.. maybe
//
#include <debug.h>
#include <assert.h>

//! This module contains modules and classes for participating in the PSYC!
//! world. See http://about.psyc.eu/ for more information about PSYC.
//! 
//! PSYC is a messaging protocol that handles communication of PSYC entities 
//! i.e., persons and chatrooms. There are other entities currently in use 
//! which will be talked about later. See @[PSYC.Person] and @[PSYC.Place].
//! 
//! PSYC entities are identified using their unique uniform. These uniforms are 
//! adresses similar to URLs. A detailed description of uniforms can be found 
//! at @[http://www.psyc.eu/unl.html]. For convenience we use objects internally
//! instead of string representations of uniforms. That way it is much easier to
//! access certain parts of uniforms. See @[MMP.Uniform] for a documentation
//! on those.
//!
//! Communication of PSYC entities is managed by one central object. Currently 
//! there exists only one such class, namely @[PSYC.Server]. There are plans to
//! implement more lightweight ones for simple applications.

class AR(function handler, array(string) wvars, int async, array(string) lvars,
	 function|string check) {
    
    string _sprintf(int type) {
	if (type == 'O') {
	    return sprintf("AR(%O, %O, lock: %O)", handler, wvars, lvars);
	}
    
	return UNDEFINED;
    }
}

AR handler_parser(void|mapping|array(string) d) {
    int async = 0;
    array(string) wvars, lvars;
    function check;

    if (mappingp(d)) {
	if (has_index(d, "async")) {
	    async = d["async"];
	} 
	
	if (has_index(d, "wvars")) {
	    wvars = d["wvars"];
	}

	if (has_index(d, "lock")) {
	    lvars = d["lock"];
	}

	if (has_index(d, "check")) {
	    check = d["check"];
	}

    } else {
	wvars = d;
    }

    enforcer(!arrayp(d) || sizeof(d),
	     "Empty set of wanted vars somewhere!! (see backtrace!)");

    return AR(0, wvars, async, lvars, check);
}

class Dummy(mixed...params) { }

//! Checks whether a PSYC mc is a generalization of another one.
//! @returns
//!	@int
//!		@value 0
//!			@expr{needle@} is not an abbreviation of @expr{haystack@}.
//!		@value 1
//!			@expr{needle@} is an abbreviation of @expr{haystack@}.
//!	@endint
int(0..1) abbrev(string haystack, string needle) {
    if (haystack == needle) return 1;

    if (sizeof(needle) < sizeof(haystack)) return 0;

    if (haystack[..sizeof(needle)-1] != needle) return 0;

    if (haystack[sizeof(needle)] == '_') return 1;

    return 0;
}

//! Base class for PSYC packets. Fits into @[MMP.Packet]s as the data part.
//! @example 
//! @code
//!PSYC.Packet p = PSYC.Packet("_message_private", ([ "_nick" : "Orgasmotron" ]), "You so suck!");
//!// now chaning the mc to _message_public, so that everyone can know.
//!p->mc = "_message_public";
//!// disguising nick to avoid trouble ,)
//!p["_nick"] = "SomeoneElse";
//! @endcode
class Packet {

    //! The mc of the packet.
    string mc;

    string cache;
    mapping (string:mixed) vars;
    
    //! Packet payload. Always needs to be a string, never make it 0!
    //! May contain a template to render the packet or arbitrary data.
    string data;

    //! @param m
    //!		The mc of the Packet.
    //! @param v
    //! 	PSYC variables set in the packet.
    //! @param d
    //! 	The packet's payload.
    void create(string|void m, mapping(string:mixed)|void v, string|void d) {
	if (m) mc = m;
	vars = v || ([ ]);
	data = d || "";
    }

    //! Casts the packet to different types.
    //! @param type
    //! 	@string
    //!			@value "string"
    //!				Will lead to the return of a rendered version of this Package.
    //!			@value "String.Buffer"
    //!				Will lead to the return of a @[String.Buffer] filled with the rendered version of this packet.
    //! 	@endstring
    //! @note
    //! 	Keep in mind that in Pike, inter-object-casts aren't possible at the time, so you need to
    //! 	@expr{packet->cast("String.Buffer")@} instead of @expr{(String.Buffer)packet@}.
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
#if defined(DEBUG) && DEBUG > 10
		return sprintf("PSYC.Packet(%O, %O, %O)", mc, vars, data);
#elif defined(DEBUG) && DEBUG > 1
		return sprintf("PSYC.Packet(%O, %O)", mc, vars);
#else
		return sprintf("PSYC.Packet(%O)", mc);
#endif
	    case 's':
		return (string)this;
	}
    }

    //! Generates a reply packet to @expr{m@}. Basically copies the packet's _tag to _tag_reply in the new packet.
    //! @returns
    //!	    The new packet containing the correct tag to be recognized as a reply to @expr{m@}.
    this_program reply(string|void mc, mapping(string:mixed)|void v, string|void d) {
	this_program m = this_program(mc, v, d);

	if (has_index(vars, "_tag") && sizeof(vars["_tag"])) {
	    m["_tag_reply"] = vars["_tag"]; 
	}

	return m;
    }

    //! Assigns a value to a packet variable.
    mixed `[]=(mixed id, mixed val) {
	cache = UNDEFINED;
	return vars[id] = val;
    }

    mixed `->=(string id, mixed val) {
	cache = UNDEFINED;
	return ::`->=(id, val);
    }

    //! Accesses a packet variable.
    mixed `[](mixed id) {
	return vars[id];
    }

    this_program clone() {
	return this_program(mc, vars + ([ ]), data);
    }
}

#if 0
Packet reply(Packet m, string|void mc, string|void data, mapping(string:mixed)|void vars) {
    Packet t = Packet(mc, data, vars);

    if (has_index(m->vars, "_tag"))
	t->vars["_tag_reply"] = m->vars["_tag"];

    return t;
}

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

//! @returns
//! @int
//! 	@value 1
//! 		@expr{thing@} is a @[Packet].
//! 	@value 0
//! 		@expr{thing@} is not a @[Packet].
//! @endint
int(0..1) is_packet(mixed thing) {
    return objectp(thing) && Program.inherits(object_program(thing), Packet);
}

//! Renders packets into neat strings based on templates either provided by the @[Packet] or the @[Text.TextDB].
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

//! @decl	string render(Packet o);
//! @decl	String.Buffer render(Packet o, String.Buffer s);
//!
//! Renders a @[Packet] into a @[string]/@[String.buffer].
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
    if (sizeof(o->data)) {
	putchar('\n');
	add(o->data);
    }

    if (to) return p; 
    return p->get();
}

//! @decl Packet parse(string data, function parse_JSON, object|void packet);
//! Parses a PSYC-Packet
//! @param data
//! 	The string to be parsed.
//! @param parse_JSON
//! 	A function to parse JSON serialized data into native Pike types.
//! @param packet
//! 	An optional @[Packet] object to store the parsed data to. Will be returned.
//! @throws
//! 	Throws an exception if the packet cannot be parsed.
//! @ignore
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
	if (strlen(data) > start+1 && data[start] == '_') { 
	    packet->mc = data[start .. ];
	    packet->data = "";
#ifdef LOVE_JSON
	    // long term plan is to make that on demand inside the packet..
	    if (stringp(lastval))
		lastval = parse_JSON(lastval);
#endif
	    if (lastmod != ':') lastkey = String.int2char(lastmod) + lastkey;
	    packet->vars += ([ lastkey : lastval ]);
	} else THROW("Method is missing.");
    } else packet->data = data;  

    return packet;
}
//! @endignore
