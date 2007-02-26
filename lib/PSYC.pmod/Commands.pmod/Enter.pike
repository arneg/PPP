// vim:syntax=lpc
#include <debug.h>
inherit PSYC.Commands.Base;

//! Provides the following commands for entering, leaving and speaking in rooms.
//! @ul
//! 	@item
//!		@expr{"enter" . Commands.Uniform|PSYC.Commands.Place@}
//! 	@item
//!		@expr{"leave" . Commands.Uniform|PSYC.Commands.Place@}
//! 	@item
//!		@expr{"say" . Commands.Uniform|PSYC.Commands.Place . Comands.String@}
//! @endul

constant _ = ([
    "enter" : ({ 
	({ "enter", 
	    ({ PSYC.Commands.Uniform|PSYC.Commands.Place, "channel" }),
	 }),
    }),
    "leave" : ({
	({ "leave",
	    ({ PSYC.Commands.Uniform|PSYC.Commands.Place, "channel" }),
	}),
    }),
    "say" : ({
	({ "say",
	    ({ PSYC.Commands.Uniform|PSYC.Commands.Place, "channel",
	       PSYC.Commands.String, "text" }),
	}),
     }),
]);

void enter(MMP.Uniform channel) {
    PT(("PSYC.Commands.Subscribe", "enter(%O)\n", channel))
    parent->client->enter(channel);
}

void leave(MMP.Uniform channel) {
    PT(("PSYC.Commands.Subscribe", "leave(%O)\n", channel))
    parent->client->leave(channel);
}

void say(MMP.Uniform channel, string text) {
    sendmsg(channel, PSYC.Packet("_message_public", 0, text));
}

