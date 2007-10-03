// vim:syntax=lpc
#include <debug.h>
inherit PSYC.Commands.Base;

//! Provides the following commands for adding people to channels and removing
//! and removing them.
//! @ul
//! 	@item
//!		@expr{"history" . PSYC.Commands.Arguments.Uniform|PSYC.Commands.Arguments.Place @}
//! @endul

constant _ = ([
    "history" : ({ 
	({ "history", 
	    ({ PSYC.Commands.Arguments.Uniform|PSYC.Commands.Arguments.Place, "channel" }),
	 }),
    }),
]);


void history(MMP.Uniform channel) {
    P3(("PSYC.Commands.History", "history(%O, %O)\n", channel, member))
    sendmsg(channel->super ? channel->super : channel, PSYC.Packet("_request_history"));
}
