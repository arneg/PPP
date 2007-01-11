// vim:syntax=lpc
#include <debug.h>
inherit PSYC.Commands.Base;

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
	       PSYC.Commands.Sentence|PSYC.Commands.String, "text" }),
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

