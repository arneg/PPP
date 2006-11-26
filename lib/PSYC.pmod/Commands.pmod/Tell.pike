// vim:syntax=lpc
#include <debug.h>
inherit PSYC.Commands.Base;

constant _ = ([
    "tell" : ({ 
	({ "tell", 
	    ({ PSYC.Commands.Uniform, "user", 
	       PSYC.Commands.String|PSYC.Commands.Sentence, "text" }),
	 }),
    }),
]);

void tell(MMP.Uniform user, string text, array(string) original_args) {
    PT(("PSYC.Commands.Tell", "tell(%O, %O, %O)\n", user, text, original_args))
    ui->client->client_sendmsg(user, PSYC.Packet("_message_private", 0, text)); 
}
