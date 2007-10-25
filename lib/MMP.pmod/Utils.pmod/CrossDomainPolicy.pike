// vim:syntax=lpc

string policy;
mapping _stream_policy = ([]);

void create(string|void domain, int|void min, void|int max,
                      int(0..1)|void insecure) {
    if (domain && !zero_type(min)) 
	allow_port_range(domain, min, max, insecure);
}

void allow_port_range(string domain, int min, void|int max, 
		      int(0..1)|void insecure) {

    if (!max) {
	max = min;
    }

    _stream_policy[domain] = ({ min, max, insecure });
    policy = UNDEFINED;
}

void deny_domain(string domain) {
    if (m_delete(_stream_policy, domain)) {
	policy = UNDEFINED;
    }
}


string render_policy() {
    if (policy) return policy;

    policy = "<cross-domain-policy>";
    foreach (_stream_policy; string domain; array a) {
	string range, fmt;

	if (!a[0]) {
	    range = "*";
	} else {
	    range = sprintf("%d-%d", a[0], a[1]);
	}

	if (a[2]) { // insecure	
	    fmt = "<allow-access-from domain=\"%s\" to-ports=\"%s\" secure=\"false\"/>";
	} else {
	    fmt = "<allow-access-from domain=\"%s\" to-ports=\"%s\"/>";
	}
	policy += sprintf(fmt, domain, range);
    }
    policy += "</cross-domain-policy>\0";

    return policy;
}
