#include <debug.h>

object server;

void create(object server_object) {
    PT(("Codec", "create(%O)\n", server_object))
    server = server_object;
}

mixed nameof(function|program|object o) {
    PT(("Codec", "nameof(%O)\n", o))

    if (MMP.is_uniform(o)) {
	return (string)o;
    }

    return UNDEFINED;
}

mixed objectof(string data) {
    PT(("Codec", "objectof(%O)\n", data))
    return server->get_uniform(data); 
}


// dummies
//
object __register_new_program(program p) {
    return 0;
}

function functionof(string data) {
    return UNDEFINED;
}

program programof(string data) {
    return UNDEFINED;
}
