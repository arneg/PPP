// vim:syntax=lpc
//
//! This class may be used to create a CrossDomainPolicy as used by Adobe Flash Player. 
//!
//! @seealso
//! 	If you want to a CrossDomainPolicy for tcp sockets, check out @[FlashFile()].

string policy;
mapping _stream_policy = ([]);


//! Creates a CrossDomainPolicy. See @[allow_port_range] for arguments.
void create(string|void domain, int|void min, void|int max,
                      int(0..1)|void insecure) {
    if (domain && !zero_type(min)) 
	allow_port_range(domain, min, max, insecure);
}

//! Allow the given domain.
//! @param domain
//! 	domain from which access is allowed
//! @param min
//! @param max
//! 	port range to be allowed
//! @param secure
//! 	if a secure (SSL/TLS) connection is required
void allow_port_range(string domain, int min, void|int max, 
		      int(0..1)|void insecure) {

    if (!max) {
	max = min;
    }

    _stream_policy[domain] = ({ min, max, insecure });
    policy = UNDEFINED;
}

//! Deny the given domain. Undos what @[allow_port_range] does.
void deny_domain(string domain) {
    if (m_delete(_stream_policy, domain)) {
	policy = UNDEFINED;
    }
}

//! Render the policy. Returns a Null-Terminated @expr{cross-domain-policy@}-tag. 
//! This is fine as a reply to a policy-file-request on a XMLsocket. In case you
//! want to use a policy in a XML file, you need to remove the trailing Null
//! and enclose this in XML document tags.
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
