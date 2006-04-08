// vim:syntax=lpc
//
#include <debug.h>

#if DEBUG
void debug(string cl, string format, mixed ... args) {
    // erstmal nix weiter
    predef::write("(%s)\t"+format, cl, @args);
}
#endif

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
	

	// we have to decide between deletions.. and "".. or 0.. or it
	// a int zero not allowed?
	if (val) {
	    if (key[0] == '_') putchar(':');
	    add(key);
	    putchar('\t');
	    
	    if (stringp(val))
		add(replace(val, "\n", "\n\t")); 
	    else if (arrayp(val))
		add(map(val, replace, "\n", "\n\t") * ("\n"+mod+"\t"));
	    else if (mappingp(val))
		add("dummy");
	    else if (intp(val))
		add((string)val);
	    
	    putchar('\n');
	
	} else {
	    if (key[0] == '_') putchar(':');
	    add(key);
	    putchar('\n');
	}
    }
}

string|String.Buffer render(mmp_p packet, void|String.Buffer to) {
    String.Buffer p;
    if (to)
	p = to;	
    else 
	p = String.Buffer();

    function add = p->add;
    function putchar = p->putchar;

    if (sizeof(packet->vars))
	MMP.render_vars(packet->vars, p);

    putchar('\n');
    
    if (stringp(packet->data)) {
	add(packet->data);
    } else {
	// TODO: every object contained in data needs a 
	// render(void|String.Buffer) method.
	add((string)packet->data);
    }
    add("\n.\n");

    if (to)
	return p;
    return p->get();
}

class mmp_p {
    mapping(string:mixed) vars;
    string|object data;

    // experimental variable family inheritance...
    // this actually does not exactly what we want.. 
    // because asking for a _source should return even _source_relay 
    // or _source_technical if present...
    void create(void|string|object d, void|mapping(string:mixed) v) {
	vars = v||([]);
	data = d||""; 
    }

    mixed cast(string type) {
	if (type == "string") {
	    return MMP.render(this);
	}
    }

    string _sprintf(int type) {
	if (type == 'O') {
	    return sprintf("MMP.mmp_p(%O, '%.15s..' )\n", vars, (string)data);
	}

	return UNDEFINED;
    }
    
    mixed `[](string id) {
	int a;
	array(string) l;
	if (has_index(vars, id)) {
	    return vars[id];
	}

	if (!is_mmpvar(id) && objectp(data)) {
	    return data[id];
	}

	return UNDEFINED;
    }

    mixed `[]=(string id, mixed val) {

	if (is_mmpvar(id)) {
	    return vars[id] = val;
	}
	
	if (objectp(data)) {
	    return data[id] = val;
	}

	throw(({ sprintf("cannot assign values to data, and %O is not am mmp "
			 "variable.", id), backtrace() }));
    }
}

// 0
// 1 means yes and merge it into psyc
// 2 means yes but do not merge

int(0..2) is_mmpvar(string var) {
    switch (var) {
    case "_target":
    case "_source":
    case "_source_relay":
    case "_source_location":
    case "_source_identification":
    case "_context":
    case "_length":
    case "_counter":
    case "_reply":
    case "_trace":
	return 1;
    case "_amount_fragments":
    case "_fragment":
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

class Queue() {
    array a = ({ });

    void push(mixed in) {
	a += ({ in });
    }

    void unshift(mixed in) {
	a = ({ in }) + a;
    }

    mixed shift() {
	mixed t;

	t = a[0];
	a = a[1..];

	return t;
    }

    mixed pop() {
	mixed t;

	t = a[-1];
	a = a[0..sizeof(a)-2];

	return t;
    }

    int _sizeof() {
	return sizeof(a);
    }

    int isEmpty() {
	return !sizeof(this);
    }

}


class Circuit {
    inherit Queue;

    Stdio.File|Stdio.FILE socket;
    string|String.Buffer inbuf;
#ifdef LOVE_TELNET
    string dl;
#endif
    mmp_p inpacket;
    mixed lastval;
    int lastmod, write_ready;
    string lastkey, peerhost;
    function msg_cb, close_cb;

    void reset() {
	lastval = lastkey = lastmod = 0;
	inpacket = mmp_p();
    }	

    // bytes missing in buf to complete the packet inpacket. (means: inpacket 
    // has _length )
    // start parsing at byte start_parse. start_parse == 0 means create a new
    // packet.
    int m_bytes, start_parse;

    // cb(received & parsed mmp_message);
    //
    // on close/error:
    // closecb(0); if connections gets closed,
    // 	 --> DISCUSS: closecb(string logmessage); on error? <--
    void create(Stdio.File|Stdio.FILE so, function cb, function closecb
		) {
	P2(("MMP.Circuit", "create(%O, %O, %O)\n", so, cb, closecb))
	socket = so;
	socket->set_nonblocking(start_read, write, close);
	peerhost = so->query_address();
	msg_cb = cb;
	close_cb = closecb;

	reset();
    }

    int write(void|mixed id) {
	if (isEmpty()) {
	    write_ready = 1;
	} else {
	    int written;
	    mixed tmp;
	    string s;

	    write_ready = 0;

	    tmp = shift();

	    // i would prefer a way to handle fragments automatically..
	    if (arrayp(tmp)) {
		[s, tmp] = tmp;
	    } else {
		s = (string)tmp;
	    }

	    written = socket->write(s);

	    P2(("MMP.Circuit", "%O wrote %d bytes.\n", this, written))

	    if (written != sizeof(s)) {
		unshift(({ s[written..], tmp }));
	    }
	}
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
	    socket->close();
	    return 1;
	}
P2(("MMP.Circuit", "%s sent a proper initialisation packet.\n", peerhost))
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
	string|int ret;

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

	array(mixed) exeption;
	if (exeption = catch {
	    while (inbuf && !(ret = 
#ifdef LOVE_TELNET
	(dl) ? parse(dl) :
#endif
		     parse()
		     )) {
		P2(("MMP.Circuit", "parsed %O.\n", inpacket))
		msg_cb(inpacket);
		reset();
	    }
	}) {
	    P0(("MMP.Circuit", "Catched an error: '%s' backtrace: %O\n", @exeption))
	    socket->close();
	}


	return 1;	
    }

    int close(mixed id) {

    }

    void send(mmp_p mmp) {
P0(("MMP.Circuit", "%O->send(%O)\n", this, mmp))
	push(mmp);

	if (write_ready) {
	    write();
	}
    }

    // works quite similar to the psyc-parser. we may think about sharing some
    // source-code. 
#define INBUF	((string)inbuf)
#ifdef LOVE_TELNET
# define LL	sizeof(linebreak)
# define LD	linebreak
    int|string parse(void|string linebreak) {
	if (!linebreak) linebreak = "\n";
#else
    int|string parse() {
# define LL	1
# define LD	"\n"
#endif
#define RETURN(x)	ret = (x); stop = -1
	string key;
	mixed val;
	int mod, start, stop, num, ret;

	ret = -1;

	// expects to be called only if inbuf is nonempty
	
	P2(("MMP.Parse", "parsing: %d from position %d\n", sizeof(inbuf), 
		      start_parse))
LINE:	while(-1 < stop && 
	      -1 < (stop = (start = (mod) ? stop+LL : start_parse, 
			    search(inbuf, LD, start)))) {

	    // check for an empty line.. start == stop
	    mod = INBUF[start];
	    P2(("MMP.Parse", "start: %d, stop: %d. mod: %c\n", start, stop, mod))
	    P2(("MMP.Parse", "parsing line: '%s'\n", INBUF[start .. stop-1]))
	    if (stop > start) switch(mod) {
	    case '.':
		// empty packet. should be accepted in any case.. 
		// this may become a PING-PONG strategy
		if (lastmod) {
		    inpacket->data = 0;
		}
		
		RETURN(0);
		break;
	    case '=':
	    case '+':
	    case '-':
	    case '?':
	    case ':':
#ifdef LOVE_TELNET
		num = sscanf(INBUF[start+1 .. stop-1], "%[A-Za-z_]%*[\t ]%s",
#else
		num = sscanf(INBUF[start+1 .. stop-1], "%[A-Za-z_]\t%s",
#endif
			     key, val);
		if (num == 0) return "parsing error";
		// this is either an empty string or a delete. we have to decide
		// on that.
		start_parse = stop+LL;
		P2(("MMP.Parse", "%s => %O \n", key, val))
		if (num == 1) val = 0;
		else if (key == "") {
		   if (mod != lastmod) return "improper list continuation";
		   if (mod == '-') return "diminishing lists is not supported";
		   if (stringp(lastval) || intp(lastval)) 
			lastval = ({ lastval, val });
		   else lastval += ({ val });
		   continue LINE;
		}
		break;
	    case '\t':
		if (!lastmod) return "invalid variable continuation";
P2(("MMP.Parse", "mmp-parse: + %s\n", INBUF[start+1 .. stop-1]))
		if (arrayp(lastval))
		    lastval[-1] += "\n" +INBUF[start+1 .. stop-1];
		else
		    lastval += "\n" +INBUF[start+1 .. stop-1];
		continue LINE;
	    default:
		return "unknown modifier "+String.int2char(mod);

	    } else {
		// this else is an empty line.. 
		// allow for different line-delimiters
		int length = inpacket["_length"];

		if (length) {
		    if (stop+LL + length > sizeof(inbuf)) {
			start_parse = start;
P2(("MMP.Parse", 
    "reached the data-part. %d bytes missing (_length specified)\n", 
    stop+LL+length-sizeof(inbuf)))
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
P2(("MMP.Parse", "reached the data-part. finished. (_length specified)\n", ))
			RETURN(0);
		    }
		    // TODO: we could cache the last sizeof(inbuf) for failed
		    // searches.. 
		} else if (-1 == (length = search(inbuf, LD+"."+LD, stop+LL))) {
		    start_parse = start;
P2(("MMP.Parse", "reached the data-part. i dont know how much is missing.\n", ))
		    RETURN(-1);
		} else {
		    inpacket->data = INBUF[stop+LL .. length];	
		    if (sizeof(inbuf) == length+2*LL+1)
			inbuf = 0;
		    else
			inbuf = INBUF[length+2*LL+1 .. ];
		    start_parse = 0;
P2(("MMP.Parse", "reached the data-part. finished.\n", ))
		    RETURN(0);
		}
	    }

	    if (lastkey) {
		inpacket[lastkey] = lastval;
	    }

	    lastmod = mod;
	    lastkey = key;
	    lastval = val;

	}

	return ret;
    }
}

class Active {
    inherit Circuit;

    void start_read(mixed id) {
	::start_read(id);

	so->write(".\n");
    }
}

class Server {
    inherit Circuit;

    void create(Stdio.File|Stdio.FILE so, function cb, function closecb) {
	::create(so, cb, closecb);

	so->write(".\n");
    }
}
