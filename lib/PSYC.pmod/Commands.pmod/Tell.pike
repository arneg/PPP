// vim:syntax=lpc
#include <debug.h>
inherit PSYC.Commands.Base;

//! Provides the tell command to talk to users privately.
//! @ul
//! 	@item
//!		@expr{"tell" . PSYC.Commands.Arguments.Uniform|PSYC.Commands.Arguments.Person . PSYC.Comands.Arguments.String@}
//! @endul

constant _ = ([
    "tell" : ({ 
	({ "tell", 
	    ({ PSYC.Commands.Arguments.Uniform|PSYC.Commands.Arguments.Person, "user", 
	       PSYC.Commands.Arguments.String, "text" }),
	 }),
    }),
]);

void tell(MMP.Uniform user, string text) {
    P3(("PSYC.Commands.Tell", "tell(%O, %O)\n", user, text))
    sendmsg(user, PSYC.Packet("_message_private", 0, text)); 
}
