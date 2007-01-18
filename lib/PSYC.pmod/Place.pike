// vim:syntax=lpc
inherit PSYC.Unl;

object context;

void create(MMP.Uniform uniform, object server) {
    
    ::create(uniform, server, PSYC.DummyStorage());
    add_handlers(PSYC.Handler.Channel(this, sendmmp, uniform),
		 Public(this, sendmmp, uniform));
    this->create_channel(uniform);
    context = server->get_context(uniform);
}

void add(MMP.Uniform guy, function cb, mixed ... args) {
    call_out(cb, 0, @args);
}


class Public {

    inherit PSYC.Handler.Base;

    constant _ = ([
	"postfilter" : ([
	    "_message_public" : 0,
	]),
    ]);

    int postfilter_message_public(MMP.Packet p, mapping _v, mapping _m) {
	
	if (!context->contains(p->source()) {
	    sendmsg(p->reply(), p->data->reply("_failure_message_public")); 
	}

	parent->castmsg(uni, PSYC.Packet(p->data->mc, 0, p->data->data), p->source());
	return PSYC.Handler.GOON;
    }
}
