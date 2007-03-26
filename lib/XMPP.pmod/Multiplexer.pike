// vim:syntax=lpc
#include <debug.h>
#include <assert.h>
// needs bugnums!!! at least for a certain amoung of keywords.. (31)
//
// i will put in defines and exceptions for that.. we could even use
// strings as a workaround.. or come up with an internal type .. or use 
// any generic bitvector.. 

constant Person = 0;
constant Room   = 1;
constant Root   = 2;
constant Any	= 3;

mapping(string:mixed) handlers = ([
]);

void add_handler(object o) {
    enforcer(mappingp(o->_),
	     "Cannot add object without specification.\n");

    foreach (o->_;string name; mapping spec) {
	function fun = `->(o, name);
	enforcer(fun, sprintf("%O does not implement function %O.\n", o, name));
	
	mixed type;
	if (has_index(spec, "type")) {
	    type = spec["type"];
	    enforcer(!intp(type) || type != Any,
		     sprintf("Multiplexer.Any is the only integer type allowed. %O not.\n", type));
	} else {
	    type = Any; 
	}

	if (!has_index(handlers, type)) {
	    handlers[type] = ({
		AttributeMatch(),
		AttributeMatch(),
		AttributeMatch(),
		AttributeMatch(),
			      });
	}

	if (has_index(spec, "to")) {
	    int to = spec["to"];
	    enforcer(intp(to) && to <= Any && to >= Person,
		     "specification 'to' must be of type integer.\n");

	} else to = Any;

	handlers[type][to]->add_handler(fun, spec["attributes"]);
    }

    void handle(Node node) {
	array(function) ret = ({ });
	string name = node->getName();
	mapping attributes = node->attributes;
	MMP.Uniform to = attributes["to"];
	int to_type;


	if (has_index(attributes, "to")) {
	    to = attributes["to"];
	    attributes -= ([ "to" : 1 ]);

	    to_type = Any; // check here for the type of to
			   // .. someone please build that.
	} else {
	    to_type = Any;
	}

	if (has_index(handlers, name)) {
	    if (has_index(handlers[name], to_type)) {
		ret += handlers[name][to_type]->match(attributes);	
	    }

	    if (to_type != Any && has_index(handlers[name], Any)) {
		ret += handlers[name][Any]->match(attributes);	
	    }
	}

	if (name != Any && has_index(handlers, Any)) {
	    if (has_index(handlers[Any], to_type)) {
		ret += handlers[Any][to_type]->match(attributes);	
	    }

	    if (to_type != Any && has_index(handlers[Any], Any)) {
		ret += handlers[Any][Any]->match(attributes);	
	    }
	}

	if (!sizeof(ret)) {
	    // did not find ANY! match.
	    return;
	}

	foreach (ret;;function fun) {
	    if (fun(node) == 0) return;
	}

    }
}

class AttributeMatch {
    
    mapping(string:int) names2bits = ([]);
    mapping(int:string) bits2names = ([]);

    mapping(int:function|array(function)) handlers = ([]);

    void add_handler(function fun, mapping spec) {
	int key = 0;
	
	foreach (spec; string attribute;) {
	    int bits;
	    if (has_index(names2bits, attribute)) {
		bits = names2bits[attribute];	
	    } else {
		bits = new_bits(attribute);
	    }

	    key |= bits;
	}

	if (has_index(handlers, key)) {
	    if (arrayp(handlers[key])) {
		handlers[key] += ({ fun });
	    } else {
		handlers[key] = ({ handlers[key], fun });
	    }
	} else {
	    handlers[key] = fun;
	}
    }

    array(function) match(mapping(string:mixed) spec) {
	int key = 0;
	int fuzzy = 0;

	foreach (spec; string attribute;) {
	    if (has_index(names2bits, attribute)) {
		key |= names2bits[attribute];
	    } else {
		fuzzy = 1;
	    }
	}

	if (has_index(handlers, key)) {
	    return handlers[key];	    
	} else {
	    array(function) ret = ({});
	    int max = 0;
	    int max_bits = 0;

	    foreach (handlers; int bits; mixed funs) {
		int and = bits & key;
		if (and != bits) continue; // attributes missing!
		int num = bit_count(and);
		
		if (num > max_bits) {
		    max_bits = num;
		    max = bits;
		    if (arrayp(funs)) {
			ret = funs;
		    } else {
			ret = ({ funs });
		    }
		} else if (num == max_bits) {
		    if (arrayp(funs)) {
			ret += funs;
		    } else {
			ret += ({ funs });
		    }
		}
	    }

	    return ret;
	}
    }

    int new_bits(string attribute) {
	int i = max(@indices(bits2names)) << 1;
	bis2names[i] = attribute;
	names2bits[attributes] = i;
	return i;
    }

    // this should be fast for sparse masks.. which we have.
    int bit_count(int n) {
	int count = 0;

	while (n) {
	    count++;
	    n &= (n - 1) ;
	}

	return count;
    }

}
