// vim:syntax=lpc
#include <debug.h>
inherit PSYC.Commands.Base;

constant _ = ([
    "subscribe" : ({ 
	({ "subscribe", 
	    ({ PSYC.Commands.Uniform, "channel" }),
	 }),
    }),
    "unsubscribe" : ({
	({ "unsubscribe",
	    ({ PSYC.Commands.Uniform, "channel" }),
	}),
    }),
]);

void subscribe(MMP.Uniform channel) {
    PT(("PSYC.Commands.Subscribe", "subscribe(%O)\n", channel))
    ui->client->subscribe(channel);
}

void unsubscribe(MMP.Uniform channel) {
    PT(("PSYC.Commands.Subscribe", "unsubscribe(%O)\n", channel))
    ui->client->unsubscribe(channel);
}
