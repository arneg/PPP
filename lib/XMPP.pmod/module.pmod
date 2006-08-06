// vim:syntax=lpc
// 
#include <debug.h>

class XMLNode {
    XMLNode parent;
    string name;
    mapping attributes;
    array(string) data;
    array(XMLNode) children;
    int depth;

    void create(string _name, mapping _attributes, XMLNode|void _parent, 
		int|void _depth) {	
	parent = _parent ? _parent : 0;
	depth = _depth ? _depth : 0;

	name = _name;
	children = ({ });
	data = ({ });
	attributes = _attributes;
    }
    void append(XMLNode node) {
	children += ({ node });
    }

    void appendData(string content) {
	data += ({ content });
    }
    string getName() { return name; }
    int getDepth() { return depth; }
    XMLNode getParent() { return parent; }
    array(XMLNode) getChildren() { return children; }
    string|array(string) getData() { return sizeof(data) == 1 ? data[0] : data; }
}


class MySocket {
    mapping(string:mixed) _config;

    Stdio.File|Stdio.FILE socket;

    void create(mapping(string : mixed) config) {
	_config = config;
    }

    void accept(Stdio.Port lsocket) {
	string peerhost;

	werror("accepted\n");
	socket = lsocket->accept();
	peerhost = socket->query_address();
	socket->set_nonblocking(read, write, close);
    }

    void logon(int success) { }

    void starttls(int isclient) {
	SSL.context ctx = SSL.context();
	if (_config["tls"] && !isclient) {
	    ctx->rsa = Standards.PKCS.RSA.parse_private_key(_config["tls"]["key"]["localhost"]);
	    ctx->certificates = ({ _config["tls"]["certificates"]["localhost"]});
	}
	ctx->random = Crypto.Random.random_string;
	socket = SSL.sslfile(socket, ctx, isclient);
	socket->set_nonblocking(read, write, close);
	socket->set_accept_callback(tls_logon);
	werror("starttls on %O done\n", this_object());
    }

    void tls_logon(mixed ... args) {
	werror("tls_logon(%O)\n", args);
    }

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

    void starttls(int isclient) {
	::starttls(isclient);
	xmlParser = xmlParser->clone();
	streamattributes = 0;
    }
    int read(mixed id, string data) {
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
	    if (node->getName() == name[1..]) {
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
	if (node) node->appendData(data);
    }

    void handle() {
	werror("handling %O\n", node);
    }

    void open_stream(mapping attr) {
	werror("openStream\n");
	streamattributes = attr;
    }
    void close_stream() {

    }
}
