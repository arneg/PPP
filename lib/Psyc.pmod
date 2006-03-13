#include <psyc.h>

class mmp_p {
    mapping(string:PMIXED) vars;
    string data;

    // experimental variable family inheritance...
    // this actually does not exactly what we want.. 
    // because asking for a _source should return even _source_relay 
    // or _source_technical if present...
    void create() {
	vars = ([]);
    }
    
    PMIXED `[](string id) {
	int a;
	array(string) l;
	PMIXED temp = vars[id];
	if (!zero_type(temp)) return temp;

	l = id[1..] / "_";
	if (sizeof(l) == 1) return temp;
	else if (sizeof(l) > 2) for (a = sizeof(l) - 2; a > 0; a--) {
	    temp = vars["_"+l[0 .. a] * "_"];
	    if (!zero_type(temp)) return temp;
	}

	return vars["_"+l[0]];
    }

    PMIXED `[]=(string id, PMIXED val) {
	vars[id] = val;
	return val;
    }
}

class psyc_p {
    inherit mmp_p;
    string mc;

    mixed cast(string type) {
	switch(type) {
	case "string":
	    return render(this_object());
	case "String.Buffer":
	    return render(this_object(), String.Buffer());
	default:
	    return 0;
	}
    }
}

string|String.Buffer render(psyc_p o, void|String.Buffer to) {
    string key, mod;
    PMIXED temp;
    String.Buffer p;

    // this could be used to render several psyc-packets/mmp-packets at once
    // into one huge string. should give some decent optimiziation
    if (to)
	p = to;	
    else 
	p = String.Buffer();

    if (mappingp(o->vars)) foreach (indices(o->vars), key) {

	if (key[0] == '_') mod = ":";
	else mod = key[0..0];
	
	temp = o->vars[key];

	// we have to decide between deletions.. and "".. or 0.. or it
	// a int zero not allowed?
	if (temp) {
	    if (key[0] == '_') p->putchar(':');
	    p->add(key);
	    p->putchar('\t');
	    
	    if (stringp(temp))
		p->add(replace(temp, "\n", "\n\t")); 
	    else if (arrayp(temp))
		p->add(map(temp, replace, "\n", "\n\t") * ("\n"+mod+"\t"));
	    else if (mappingp(temp))
		p->add("dummy");
	    else if (intp(temp))
		p->add((string)temp);
	    
	    p->putchar('\n');
	
	} else {
	    if (key[0] == '_') p->putchar(':');
	    p->add(key);
	    p->putchar('\n');
	}
    }

    p->add(o->mc);
    p->putchar('\n');
    if (o->data) p->add(o->data);

    if (to) return p; 
    return p->get();
}

// returns a psyc_p or an error string
#ifdef LOVE_TELNET
psyc_p|string parse(string data, string|void linebreak) {
    if (linebreak == 0) linebreak = "\n";
#else
psyc_p|string parse(string data) {
    constant linebreak = "\n";
#endif
    int start, stop, num, lastmod, mod;
    string key, lastkey; 
    PMIXED lastval, val;

    psyc_p packet = psyc_p();
    packet->vars = ([]);

// may look kinda strange, but i use continue as a goto ,)
// .. also a < is not expensive at all. this could be an != actually...
LINE:while (-1 < stop &&
	    -1 < (stop = (start= (lastmod) ? stop+1 : 0, 
		  search(data, linebreak, start)))) {

	
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


