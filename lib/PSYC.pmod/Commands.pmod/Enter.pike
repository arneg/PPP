// vim:syntax=lpc
#include <debug.h>
inherit PSYC.Commands.Base;

constant _ = ([
    "enter" : ({ 
	({ "enter", 
	    ({ PSYC.Commands.Uniform, "channel" }),
	 }),
    }),
    "leave" : ({
	({ "leave",
	    ({ PSYC.Commands.Uniform, "channel" }),
	}),
    }),
]);

void enter(MMP.Uniform channel) {
    PT(("PSYC.Commands.Subscribe", "enter(%O)\n", channel))
    ui->client->enter(channel);
}

void leave(MMP.Uniform channel) {
    PT(("PSYC.Commands.Subscribe", "leave(%O)\n", channel))
    ui->client->leave(channel);
}

