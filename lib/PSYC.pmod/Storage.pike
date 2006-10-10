// first implementation of async storage.
#include <debug.h>

function default_cb;
// queue.
mapping(string:multiset(array)) requested = ([ ]);

// this should be static.. but since defining it here would fuck the hole
// thing up during inheritance we need to define/initialize that in the
// inheriting class.
//
// static mapping(string:array(string)) method2vars;

void fetch(string var);

void set_default_cb(function cb) {
    default_cb = cb;
}

// we should think about having a second sets of variables which have to be
// requested from a client (the user)
//
// we could maybe not use this register and let the user hardcode the mapping
// in the inheriting class instead.
void register_method(string method, array(string) variables) {
    if (sizeof(variables) == 0) return;
    method2vars[method] = variables;
}


// called by the underlying low level fetcher (file, sql, ...)
void fetched(string var) {
    if (has_index(requested, var)) {
	foreach(requested[var]; array t;) {
	    if (t[0] == 1) {
		call_out(t[1], 0, t[2]);
		requested[var] -= (< t >);
	    }
	    t[0]--;
	}
    }
}

// the message multiplexer.
void msg(MMP.Packet p) {
    
    // find the methods.
    //
    PSYC.Packet m = p->data;
    string t = m->mc;
    array(string) l = t / "_";
    function f;
    int i = sizeof(l)-1;

    // the functionp check is propably not nesessary and could be enforced by
    // exceptions thrown by trying to call a non-function value.
    while (!has_index(this, t) || !functionp(f = this[t])) {
	if (i == 1) {
	    if (!(f = default_cb)) {
		P1(("%O\tmessage(%s) got lost because neither a method for the specific mc nor a default method was set.\n", this, m->mc))
	    }
	    break; 
	} else {
	    i--;
	    t = l[0..i] * "_";
	}
    }

    // request vars and keep f until everything has been fetched.
    if (!has_index(method2vars, t)) {
	call_out(f, 0, p);
	return;
    }
    
    l = method2vars[t];

    if (sizeof(l) == 0) {
#if 0
	// maybe not
	m_delete(method2vars, t);
#endif
	call_out(f, 0, p);
	return;
    }

    array(mixed) blu = ({ sizeof(l), f, p });

    foreach (method2vars[t]; string var;) {
	if (!has_index(requested, var)) {
	    requested[var] = (< blu >);
	} else {
	    requested[var] += (< blu >);
	}
	fetch(var);
    }
}
