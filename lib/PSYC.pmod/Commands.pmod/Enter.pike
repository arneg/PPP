// vim:syntax=lpc
#include <debug.h>
inherit PSYC.Commands.Base;

//! Provides the following commands for entering, leaving and speaking in rooms.
//! @ul
//! 	@item
//!		@expr{"enter" . PSYC.Commands.Arguments.Uniform|PSYC.Commands.Arguments.Place@}
//! 	@item
//!		@expr{"leave" . PSYC.Commands.Arguments.Uniform|PSYC.Commands.Arguments.Place@}
//! 	@item
//!		@expr{"say" . PSYC.Commands.Arguments.Uniform|PSYC.Commands.Arguments.Place . Comands.Arguments.String@}
//! @endul

constant _ = ([
    "enter" : ({ 
	({ "enter", 
	    ({ PSYC.Commands.Arguments.Uniform|PSYC.Commands.Arguments.Place, "channel" }),
	 }),
    }),
    "leave" : ({
	({ "leave",
	    ({ PSYC.Commands.Arguments.Uniform|PSYC.Commands.Arguments.Place, "channel" }),
	}),
    }),
    "say" : ({
	({ "say",
	    ({ PSYC.Commands.Arguments.Uniform|PSYC.Commands.Arguments.Place, "channel",
	       PSYC.Commands.Arguments.String, "text" }),
	}),
     }),
]);

void enter(MMP.Uniform channel) {
    P3(("PSYC.Commands.Subscribe", "enter(%O)\n", channel))
    parent->subscribe(channel);
}

void leave(MMP.Uniform channel) {
    P3(("PSYC.Commands.Subscribe", "leave(%O)\n", channel))
    parent->unsubscribe(channel);
}

void say(MMP.Uniform channel, string text) {
    sendmsg(channel, PSYC.Packet("_message_public", 0, text));
}

