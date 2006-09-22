// vim:syntax=lpc
// 
#include <debug.h>

class XMLNode {
    XMLNode parent;
    string name;
    mapping attributes;
    array(string) data;
    array(string|XMLNode) children;
    int depth;

    void create(string _name, mapping _attributes, XMLNode|void _parent, 
		int|void _depth) {	
	parent = _parent ? _parent : 0;
	depth = _depth ? _depth : 0;

	name = _name;
	attributes = _attributes;
	children = ({ });
    }
    void append(string|XMLNode node) {
	children += ({ node });
    }

    mixed `->(string dings) {
	if (attributes[dings]) {
	    return attributes[dings];
	}
	return ::`->(dings);
    }

    string getName() { return name; }
    int getDepth() { return depth; }
    XMLNode getParent() { return parent; }
    array(XMLNode) getChildren() { 
	return filter(children, objectp); 
    }
    string|array(string) getData() {
	array (string) d = filter(children, stringp);
	return sizeof(d) == 1 ? d[0] : d; 
    }

    string renderXML() {
	string s = "<" + name + " ";
	foreach(attributes; string key; string val) {
	    s += key + "='" + val + "' "; 
	}
	if (!sizeof(children)) 
	    return s + "/>";
	s += ">";

	foreach(children;; mixed item) {
	    if (objectp(item))
		s += item->renderXML();
	    else
		s += item;
	}
	return s + "</" + name + ">";
    }
}

class Packet {
    void create(XMLNode|void val) {
    }
}

/* request response packet which installs a callback */
class Query {
    inherit Packet;
}

class MySocket {
    mapping(string:mixed) config;

    IRC.Utils.BufferedStream socket;

    void create(mapping(string : mixed) _config) {
	config = _config;
    }

    string accept(Stdio.Port _socket) {
	socket = IRC.Utils.BufferedStream();
	socket->assign(_socket->accept());
	socket->set_buffered(read, close);
	socket->___read_callback = socket->query_read_callback();
	return socket->query_address();
    }

#ifdef SSL_WORKS
    void starttls(int isclient) {
	werror("%O starttls isclient %d\n", this_object(), isclient);
	SSL.context ctx = SSL.context();
	if (config["tls"]) {
	    ctx->rsa = Standards.PKCS.RSA.parse_private_key(config["tls"]["key"]["localhost"]);
	    ctx->certificates = ({ config["tls"]["certificates"]["localhost"]});
	}
	ctx->random = Crypto.Random.random_string;
	//Strong ciphersuites.
	ctx->preferred_suites = ({
				 SSL.Constants.SSL_rsa_with_idea_cbc_sha,
				 SSL.Constants.SSL_rsa_with_rc4_128_sha,
				 SSL.Constants.SSL_rsa_with_rc4_128_md5,
				 SSL.Constants.SSL_rsa_with_3des_ede_cbc_sha,
				 });
//	ctx->auth_level = SSL.Constants.AUTHLEVEL_require;
	socket = SSL.sslfile(socket, ctx, isclient);
	socket->set_nonblocking(0, tls_connected, tls_failed);
    }

    void tls_connected(mixed ... args) {
	werror("tls_connected(%O)\n", args);
	socket->set_nonblocking(read, write, close);
    }

    void tls_failed(mixed ... args) {
	werror("tls_failed(%O)\n", args);
    }
    void tls_logon(mixed ... args) {
	werror("tls_logon(%O)\n", args);
	werror("cert info: %O\n", socket->get_peer_certificate_info());
    }
#endif

    int read(mixed id, string data) {
	werror("read called\n");
	// ...
    }

    int write(void|mixed id) {
	// ...
	return 1;
    }

    int close(mixed id) {
	// ...
    }
}


class XMPPSocket {
    inherit MySocket;
    Parser.HTML xmlParser;

    mapping streamattributes;
    string innerxml;
    XMLNode node;

    void create(mapping(string:mixed) config) {
	xmlParser = Parser.get_xml_parser();
	xmlParser->_set_tag_callback(onTag);
	xmlParser->_set_data_callback(onData);

	::create(config);
    }
#if def SSL_WORKS
    void starttls(int isclient) {
	::starttls(isclient);
	xmlParser = xmlParser->clone();
	streamattributes = 0;
    }
#endif

    int read(mixed id, string data) {
//	werror("%O << %O\n", this_object(), data);
	xmlParser->feed(data);
    }

    int onTag(Parser.HTML p, string tag) {
	string name;
	mapping attr = ([ ]);

	if ( tag[-2] == '/' ) {
	    attr["/"] = "/";
	    tag[-2] = ' ';
	}
	attr += p->parse_tag_args(tag);
    
	foreach(indices(attr), string a ) {
	    if ( a != "/" && attr[a] == a ) {
		name = a;
		m_delete(attr, name);
		break;
	    }
	}

	if (streamattributes == 0) {
	    if (name == "stream:stream")
		open_stream(attr);
	    else if (name == "/stream:stream") 
		close_stream();
	    else {
		werror("tag is %O\n", tag);
		throw("irgendwas anderes als ein xml stream?");
	    }
	    return 0;
	}
	if (name[0] == '/') {
	    if (name[1..] == "stream:stream") {
		close_stream();
	    }
	    else if (node->getName() == name[1..]) {
		if (node->getParent()) 
		    node = node->getParent();
		else {
		    handle();
		    node = 0;
		}
	    } else {
		throw("unbalanced xml\n");
	    }

	} else if (attr["/"] == "/") {
	    m_delete(attr, "/");
	    if (node) node->append(XMLNode(name, attr));
	    else {
		node = XMLNode(name, attr);
		handle();
		node = 0;
	    }
	} else {
	    XMLNode t;
	    if (node) {
		t = XMLNode(name, attr, node, node->getDepth() + 1);
		node->append(t);
	    } else
		t = XMLNode(name, attr);
	    node = t;
	}
    }

    int onData(Parser.HTML p, string data) {
	if (node) node->append(data);
    }

    void handle() {
	werror("handling %O\n", node);
    }

    void open_stream(mapping attr) {
	werror("%O open_stream\n", this_object());
	streamattributes = attr;
    }
    void close_stream() {
	werror("%O close stream\n", this_object());
    }

    void disconnect(void|mixed reason) {
	// </stream:stream>
    }
}
