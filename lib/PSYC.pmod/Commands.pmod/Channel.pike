// vim:syntax=lpc
#include <debug.h>
inherit PSYC.Commands.Base;

//! Provides the following commands for adding people to channels and removing
//! and removing them.
//! @ul
//! 	@item
//!		@expr{"channel_add" . PSYC.Commands.Arguments.Uniform|PSYC.Commands.Arguments.Channel . PSYC.Commands.Arguments.Uniform@}
//! 	@item
//!		@expr{"channel_remove" . PSYC.Commands.Arguments.Uniform|PSYC.Commands.Arguments.Channel . PSYC.Commands.Arguments.Uniform@}
//! @endul

constant _ = ([
    "channel_add" : ({ 
	({ "channel_add", 
	    ({ PSYC.Commands.Arguments.Uniform|PSYC.Commands.Arguments.Channel, "channel",
	       PSYC.Commands.Arguments.Uniform, "member" }),
	 }),
    }),
    "channel_remove" : ({
	({ "channel_remove",
	    ({ PSYC.Commands.Arguments.Uniform|PSYC.Commands.Arguments.Channel, "channel",
	       PSYC.Commands.Arguments.Uniform, "member" }),
	}),
    }),
]);

void channel_add(MMP.Uniform channel, MMP.Uniform member) {
    P3(("PSYC.Commands.Channel", "channel_add(%O, %O)\n", channel, member))
    sendmsg(channel->super, PSYC.Packet("_request_member_add", ([ "_member" : member ])));
}

void channel_remove(MMP.Uniform channel, MMP.Uniform member) {
    P3(("PSYC.Commands.Channel", "channel_remove(%O, %O)\n", channel, member))
    sendmsg(channel->super, PSYC.Packet("_request_member_remove", ([ "_member" : member ])));
}
