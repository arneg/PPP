// vim:syntax=lpc
#include <debug.h>
inherit PSYC.Commands.Base;

//! Provides the tell command to talk to users privately.
//! @ul
//! 	@item
//!		@expr{"tell" . Commands.Uniform|PSYC.Commands.Person . Comands.String@}
//! @endul

constant _ = ([
    "tell" : ({ 
	({ "tell", 
	    ({ PSYC.Commands.Uniform|PSYC.Commands.Person, "user", 
	       PSYC.Commands.String, "text" }),
	 }),
    }),
]);

void tell(MMP.Uniform user, string text) {
    P3(("PSYC.Commands.Tell", "tell(%O, %O)\n", user, text))
    sendmsg(user, PSYC.Packet("_message_private", 0, text)); 
}
