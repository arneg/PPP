// vim:syntax=lpc
#include <debug.h>
mapping handlers = ([]);
// temporary
mapping(string:function) exports = ([]);

// would be "postfilter" and MethodMultiplexer
void register_handler(string name, object handler) {

    if (!has_index(handler, name)) {
	THROW(sprintf("%O does not offer %O.\n", handler, name));
    }

    handlers[name] = handler;
}

void handle(string name, mixed ... args) {

    if (!has_index(handlers, name)) {
	P0(("PSYC.Handling", "No handling registered for %O.\n", name))	
	return;
    }

    object handler = handlers[name];

    predef::`->(handler, name)(@args);
}

void add_handlers(object ... h) { 
    P2(("Handling", "add_handler(%O) in %O\n", h, this))
    foreach (h;; object handler) {
	mapping temp = handler->_;

	foreach (temp; string name; mixed cred) {
	    if (has_index(handlers, name)) {
		predef::`->(handlers[name], "add_"+name)(handler, cred);
	    }
	}
    }

    do_import(@h);
}

void do_import(PSYC.Handler.Base ... handlers) {
    foreach (handlers;; PSYC.Handler.Base handler) {
	if (has_index(handler, "export")) {
	    foreach (handler->export;;string fun) {
		exports[fun] = predef::`->(handler, fun);
	    }
	}
    }
}

mixed `->(string name) {
    if (has_index(exports, name)) {

	return exports[name];
    } 

    // we want to call ::`->(), but thats for 
    // pike 7.7 only.
    return this[name];
}

