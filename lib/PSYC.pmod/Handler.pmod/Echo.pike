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
    PSYC.Packet m = p->data;
   
    PSYC.Packet echo = m->reply("_echo" + m->mc, m->vars, m->data);
    sendmsg(p->source(), echo);

    return PSYC.Handler.GOON;
}
