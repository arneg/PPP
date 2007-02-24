// vim:syntax=lpc

inherit PSYC.Handler.Base;

//! Simple handler providing @expr{_message_private@} echoes.
//!
//! Requires no variables from storage whatsoever.

constant _ = ([
    "postfilter" : ([
	"_message_private" : 0,
    ]),
]);

int postfilter_message_private(MMP.Packet p, mapping _v, mapping _m) {
   
    PSYC.Packet echo = p->data->reply("_echo" + p->data->mc, p->data->vars, p->data->data);
    sendmsg(p->source(), echo);

    return PSYC.Handler.GOON;
}
