#include <new_assert.h>
inherit MMP.Utils.Debug;

object server;

void create(mapping params) {
    ::create(params["debug"]);
    enforce(objectp(server = params["server"]));
}

mixed nameof(function|program|object o) {
    debug("serialization", 6, "nameof(%O)\n", o);

    if (MMP.is_uniform(o)) {
	return (string)o;
    }

    return UNDEFINED;
}

mixed objectof(string data) {
    debug("serialization", 6, "objectof(%O)\n", data);
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
