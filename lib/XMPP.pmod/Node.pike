/*
 * basic xmpp element - like a xml node, but with a more convenient api
 */
#include <debug.h>
string name;
mapping attributes;
array(string|XMPP.Node) children;

void create(string _name, mapping|void _attributes, 
	    array(string|XMPP.Node)|void _children) {
    name = _name;
    if (_attributes)
	attributes = _attributes;
    else 
	attributes = ([ ]);
    if (_children)
	children = _children;
    else 
	children = ({ });
}
void append(string|XMPP.Node node) {
    children += ({ node });
}

mixed `->(string dings) {
    if (attributes[dings]) {
	return attributes[dings];
    }
    return ::`->(dings);
}

mixed `->=(string key, mixed val) {
    attributes[key] = val;
}

string getName() { return name; }
array(XMPP.Node) getChildren() { 
    return filter(children, objectp); 
}
XMPP.Node firstChild() {
    for (int i = 0; i < sizeof(children); i++)
	if (objectp(children[i])) return children[i];
    return 0;
}
string|array(string) getData() {
    array (string) d = filter(children, stringp);
    return sizeof(d) == 1 ? d[0] : d; 
}

string renderXML() {
    string s = "<" + name;
    foreach(attributes; string key; string val) {
	s += " " + key + "='" + val + "'"; 
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
