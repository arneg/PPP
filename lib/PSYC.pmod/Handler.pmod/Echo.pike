// vim:syntax=lpc

inherit PSYC.Handler.Base;

constant _ = ([
    "postfilter" : ([
	"_message_private" : 0,
    ]),
]);

int postfilter_message_private(MMP.Packet p, mapping _v, mapping _m) {
   
    PSYC.Packet echo = p->data->reply("_echo" + p->data->mc, p->data->data,
				      p->data->vars);
    uni->sendmsg(p->source(), echo);

    return PSYC.Handler.GOON;
}
