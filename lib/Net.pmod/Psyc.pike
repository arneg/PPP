#define LOVE_TELNET
#include <psyc.h>
// try to do some smart parsing + buffering. in many cases we have to re-parse
// a packet when it has not been transmitted completely. 
//
// maybe we should have some checks for
// - maximum length of the inbuffer
class Circuit {
    inherit Net.Circuit;

    string|String.Buffer inbuf;
    string dl;
    Psyc.mmp_p inpacket;
    PMIXED lastval;
    int lastmod;
    string lastkey;
    function msg_cb;

    void reset() {
	lastval = lastkey = lastmod = 0;
	inpacket = Psyc.mmp_p();
    }	

    // bytes missing in buf to complete the packet inpacket. (means: inpacket 
    // has _length )
    // start parsing at byte start_parse. start_parse == 0 means create a new
    // packet.
    int m_bytes, start_parse;

    // wir brauchen eventuell noch ne callback für anderes als dolle messages
    // vielleicht eine für den falls, dass wir die connection zumachen wollen
    // ... böse andere seite schickt unfug etc.
    void create(Stdio.File so, function cb, string|void host, int|void port) {
	so->set_nonblocking(start_read, write, close);
	msg_cb;

	reset();
	
	::create(so, host, port);
    }

    int write(mixed id) {

    }

    int start_read(mixed id, string data) {

	// is there anyone who would send \n\r ???
	if (data[0 .. 2] == ".\n\r") {
	    dl = "\n\r";
	    if (sizeof(data) > 3)
		read(0, data[3..]);
	} else if (data[0 .. 2] == ".\r\n") {
	    dl = "\r\n";
	    if (sizeof(data) > 3)
		read(0, data[3..]);
	} else if (data[0 .. 1] != ".\n") {
	    socket->close();
	} else if (sizeof(data) > 2)
	    read(0, data[2 ..]);

	socket->set_read_callback(read);
    }

    int read(mixed id, string data) {
	string|int ret;

	predef::write("%O\n", this_object());
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

#ifdef LOVE_TELNET
	if (dl)
	    ret = parse(dl);
	else
#endif
	    ret = parse();


	if (!ret) {
	    string t;
	    predef::write("packet: %O\n", inpacket);

	    if (t = inpacket["_target"]) {
		Psyc.psyc_p p = Psyc.parse(inpacket->data);
		if (stringp(p)) {
		    predef::write("psyc-parser said: %s\n", p);
		    socket->close();
		} else msg_cb(p);
		// man könnte hier auch zum beispiel vereinbaren, dass man 
		// die connection zumacht, wenn die msg_cb irgendwas
		// bestimmtes returned
		// TODO
	    } else {
		predef::write("not target!\n");
		socket->close();
	    }
	    reset();

	} else if (stringp(ret)) { 
	    predef::write(ret+"\n");
	    socket->close();
	}

	return 1;	
    }

    int close(mixed id) {

    }

    // works quite similar to the psyc-parser. we may think about sharing some
    // source-code. 
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
	PMIXED val;
	int mod, start, stop, num, ret;

	ret = -1;
	
	predef::write("parsing: %d from position %d\n", sizeof(inbuf), 
		      start_parse);
LINE:	while(-1 < stop && 
	      -1 < (stop = (start = (mod) ? stop+LL : start_parse, 
			    search(inbuf, LD, start)))) {

	    // check for an empty line.. start == stop
	    mod = inbuf[start];
	    predef::write("start: %d, stop: %d. mod: %c\n", start, stop, mod);
	    predef::write("parsing line: '%s'\n", inbuf[start .. stop-1]);
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
		num = sscanf(inbuf[start+1 .. stop-1], "%[A-Za-z_]%*[\t ]%s",
#else
		num = sscanf(inbuf[start+1 .. stop-1], "%[A-Za-z_]\t%s",
#endif
			     key, val);
		if (num == 0) return "parsing error";
		// this is either an empty string or a delete. we have to decide
		// on that.
		start_parse = stop+LL;
		predef::write("mmp-parse: %s => %O (%O)\n", key, val, 
			      inbuf[start+1..stop-1]);
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
	    predef::write("mmp-parse: + %s\n", inbuf[start+1 .. stop-1]);
		if (arrayp(lastval))
		    lastval[-1] += "\n" +inbuf[start+1 .. stop-1];
		else
		    lastval += "\n" +inbuf[start+1 .. stop-1];
		continue LINE;
	    default:
		return "unknown modifier "+String.int2char(mod);

	    } else {
		// this else is an empty line.. 
		// allow for different line-delimiters
		int length = inpacket->vars["_length"];

		if (length) {
		    if (stop+LL + length > sizeof(inbuf)) {
			start_parse = start;
			RETURN(stop+LL+length-sizeof(inbuf));
		    } else {
			inpacket->data = inbuf[stop+LL .. stop+LL+length];
			if (sizeof(inbuf) == stop+3*LL+length+1)
			    inbuf = 0;
			else
			    inbuf = inbuf[stop+length+3*LL+1 .. ];
			start_parse = 0;
			RETURN(0);
		    }
		} else if (-1 == (length = search(inbuf, LD+"."+LD, stop+LL))) {
		    start_parse = start;
		    RETURN(-1);
		} else {
		    inpacket->data = inbuf[stop+LL .. length];	
		    if (sizeof(inbuf) == length+2*LL+1)
			inbuf = 0;
		    else
			inbuf = inbuf[length+2*LL+1 .. ];
		    start_parse = 0;
		    RETURN(0);
		}
	    }

	    if (lastmod != 0) {
		if (lastmod != ':') 
		    lastkey = String.int2char(lastmod) + lastkey;
		inpacket->vars += ([ lastkey : lastval ]);
	    }

	    lastmod = mod;
	    lastkey = key;
	    lastval = val;

	}

	return ret;
    }
}
