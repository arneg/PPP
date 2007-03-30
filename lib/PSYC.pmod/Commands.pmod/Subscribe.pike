// vim:syntax=lpc
#include <debug.h>
inherit PSYC.Commands.Base;

constant _ = ([
    "subscribe" : ({ 
	({ "subscribe", 
	    ({ PSYC.Commands.Uniform|PSYC.Commands.Place, "channel" }),
	 }),
    }),
    "unsubscribe" : ({
	({ "unsubscribe",
	    ({ PSYC.Commands.Uniform|PSYC.Commands.Place, "channel" }),
	}),
    }),
]);

void subscribe(MMP.Uniform channel) {
    P3(("PSYC.Commands.Subscribe", "subscribe(%O)\n", channel))
    parent->client->subscribe(channel);
}

void unsubscribe(MMP.Uniform channel) {
    P3(("PSYC.Commands.Subscribe", "unsubscribe(%O)\n", channel))
    parent->client->unsubscribe(channel);
}

