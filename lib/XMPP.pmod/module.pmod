// vim:syntax=lpc
// 
#include <debug.h>

class XMLNode {
    XMLNode parent;
    string tag;
    mapping attributes;
    array(string) data;
    array(XMLNode) children;
    int depth;

    void create(string name, mapping attr, XMLNode|void _parent, 
		int|void _depth) {	
	parent = _parent ? _parent : 0;
	depth = _depth ? _depth : 0;

	tag = name;
	children = ({ });
	data = ({ });
	attributes = attr;
    }
    void append(XMLNode node) {
	children += ({ node });
    }

    void appendData(string content) {
	data += ({ content });
    }
    string getName() { return tag; }
    int getDepth() { return depth; }
    XMLNode getParent() { return parent; }
    string|array(string) getData() { sizeof(data) == 1 ? data[0] : data; }
}

class XMPPSocket {
    mapping(string : mixed) _config;
    Stdio.File|Stdio.FILE socket;
    SSL.sslfile sslsocket;
    Parser.HTML xmlParser;

    mapping streamattributes;
    string innerxml;
    XMLNode node;

    void create(mapping(string:mixed) config) {
	xmlParser = Parser.get_xml_parser();
	xmlParser->_set_tag_callback(onTag);
	xmlParser->_set_data_callback(onData);

	_config = config;
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
		throw("irgendwas anderes als ein xml stream?\n");
	    }
	    return 0;
	}
	if (name[0] == '/') {
	    if (node->getName() == name[1..]) {
		if (node->getParent()) 
		    node = node->getParent();
		else
		    handle();
	    } else {
		throw("unbalanced xml\n");
	    }

	} else if (attr["/"] == "/") {
	    m_delete(attr, "/");
	    if (node) node->append(XMLNode(name, attr));
	    else {
		node = XMLNode(name, attr);
		handle();
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
	node = 0;
    }

    void open_stream(mapping attr) {
	werror("openStream\n");
	streamattributes = attr;
    }
    void close_stream() {

    }
}
