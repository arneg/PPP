#include <new_assert.h>
inherit MMP.Utils.Debug : deb;
inherit Serialization.Signature : ser;
inherit Serialization.BasicTypes;
inherit Serialization.PsycTypes;

//! Tools for message handlers
//! @note
//!	This class gets inherited by @[Handler.Base] and @[Commands.Base] as a minimal set of functionality.

object parent;
function _send_message;
MMP.Uniform uni;
mapping outgoing = ([ ]);

// we tried optional, but that doesn't work - might be a bug, we'll ask the
// pikers soon. in the meantime, we'll use static.
//! @param d
//! 	The @[MMP.Utils.DebugManager] managing debug outputs (and throws).
//! @param o
//!	Object to be added to via @[add_handler] or @[add_command] in the @[StageHandler] or @[CommandSingleplexer] api, respectively.
//! @param fun
//!	The sendmmp of o
//! @param uniform
//!	The uniform of the object in need of @[HandlingTool]'s services. Used as source address in unicast packets.
//! @note
//!	In most cases it should me most convenient to simply inherit Base Handlers.
//! @seealso
//!	@[Handler.Base], @[Commands.Base]
static void create(mapping params) {
    deb::create(params["debug"]);
    ser::create(params["type_cache"]);

    enforce(objectp(parent = params["parent"]));
    enforce(MMP.is_uniform(uni = params["uniform"]));
    enforce(callablep(_send_message = params["send_message"]));
}

void register_outgoing(mapping spec) {
    outgoing[spec["method"]->base] = spec;
}

void register_incoming(mapping spec) {
    parent->add_method(spec, this);
}

.Message get_message(MMP.Packet p) {
    mapping handler = outgoing[p->data->mc];

    return .Message(([
		    "mmp" : p,
		    "vsig" : handler->vsig,
		    "dsig" : handler->dsig,
		    "packet" : p->data,
		    "snapshot" : parent->get_outstate(p)->get_snapshot(),
		 ]));

}

void send_message(.Message m) {
    _send_message(m);
}

void register_storage(string name, object signature) {
    parent->storage->register_storage(name, signature);
}
