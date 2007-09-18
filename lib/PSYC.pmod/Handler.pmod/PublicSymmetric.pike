// vim:syntax=lpc
#include <debug.h>

inherit PSYC.Handler.Base;

//! This Handler may be used for Channels only.
constant _ = ([ 
]);

constant export = ({ "enter", "leave" });

void enter(MMP.Uniform someone, function callback, mixed ... args) {
    PT(("Handler.Public", "%O: %O asks for membership. args: %O\n", this, someone, args))

    if (MMP.is_person(someone)) {
	
	void _callback(int error, mixed args) {
	    if (error) {
		callback(0, @args);
		P0(("Handler.Public", "%O: %O wont let me join his presence. i therefore wont let him subscribe me.\n", this, someone))
	    } else {
		callback(1, @args); 
		parent->castmsg(PSYC.Packet("_notice_context_enter"), someone);
		parent->handle("notify", "member_entered", someone);
	    }
	};

	// parent->parent is the psyc-object not the channel
	parent->parent->enter(someone, _callback, args);
    } else {
	P0(("Handler.Public", "Got enter request from non-person %O.\n", someone))
	callback(0, @args);
    }
}

void leave(MMP.Uniform someone) {
    parent->castmsg(PSYC.Packet("_notice_context_leave"), someone);
    parent->handle("notify", "member_left", someone);
}
