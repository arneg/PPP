#include <debug.h>

object server;

void create(object server_object) {
    P4(("Codec", "create(%O)\n", server_object))
    server = server_object;
}

mixed nameof(function|program|object o) {
    P4(("Codec", "nameof(%O)\n", o))

    if (MMP.is_uniform(o)) {
	return (string)o;
    }

    return UNDEFINED;
}

mixed objectof(string data) {
    P4(("Codec", "objectof(%O)\n", data))
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
