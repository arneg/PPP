#include <debug.h>

//! Tools for message handlers
//! @note
//!	This class gets inherited by @[Handler.Base] and @[Commands.Base] as a minimal set of functionality.

object parent;
function sendmmp;
MMP.Uniform uni;

// we tried optional, but that doesn't work - might be a bug, we'll ask the
// pikers soon. in the meantime, we'll use static.
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
static void create(object o, function fun, MMP.Uniform uniform) {
    parent = o;
    uni = uniform;

    sendmmp = fun;
}

//! Send a unicast packet
//! @param target
//!	Intended receiver of the @[PSYC.Packet].
//! @param m
//!	@[PSYC.Packet] to be sent.
void sendmsg(MMP.Uniform target, PSYC.Packet m) {
    P2(("PSYC.Unl", "sendmsg(%O, %O)\n", target, m))
    MMP.Packet p = MMP.Packet(m);
    sendmmp(target, p);    
}

//! @decl string send_tagged(MMP.Uniform target, PSYC.Packet m, function callback, mixed ... args);
//! @decl string send_tagged_v(MMP.Uniform target, PSYC.Packet m, multiset(string)|mapping wvars, function callback, mixed ... args);
//! Tag and send a unicast packet.
//! @param target
//!	Intended receiver of the @[PSYC.Packet].
//! @param m
//!	@[PSYC.Packet] to be sent.
//! @param wvars
//!	Storage variables that should be fetched and passed on to the callback.
//! @param callback
//! 	Callback to call when the reply arrives. Will be called as
//!@code
//!void callback(MMP.Packet p, mapping storage_vars, mixed ... args) // signature of callback for send_tagged_v
//!void callback(MMP.Packet p, mixed ... args) // signature of callback for send_tagged
//!@endcode
//! @param args
//!	Optional arguments that will be passed on to the callback.
//! @returns
//! 	The tag that the packet got assigned.

string send_tagged(MMP.Uniform target, PSYC.Packet m, 
		   function callback, mixed ... args) {
    return send_tagged_v(target, m, 0, callback, @args);
}

string send_tagged_v(MMP.Uniform target, PSYC.Packet m, multiset(string)|mapping wvars,
		     function callback, mixed ... args) {
    m->vars["_tag"] = parent->make_reply(callback, wvars, @args);
    call_out(sendmsg, 0, target, m);
    return m["_tag"];
}

