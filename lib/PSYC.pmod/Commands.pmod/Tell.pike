// vim:syntax=lpc
#include <debug.h>
inherit PSYC.Commands.Base;

//! Provides the tell command to talk to users privately.
//! @ul
//! 	@item
//!		@expr{"tell" . Commands.Uniform|PSYC.Commands.User . Comands.String|Commands.Sentence@}
//! @endul

constant _ = ([
    "tell" : ({ 
	({ "tell", 
	    ({ PSYC.Commands.Uniform|PSYC.Commands.User, "user", 
	       PSYC.Commands.String|PSYC.Commands.Sentence, "text" }),
	 }),
    }),
]);

void tell(MMP.Uniform user, string text, array(string) original_args) {
    PT(("PSYC.Commands.Tell", "tell(%O, %O, %O)\n", user, text, original_args))
    sendmsg(user, PSYC.Packet("_message_private", 0, text)); 
}
