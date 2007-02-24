// vim:syntax=lpc
inherit PSYC.Unl;
//! A minimal implementation of a chatroom.

object context;

//! @param uni
//! 	Uniform of the room.
//! @param server
//! 	A server object providing mmp message delivery.
//! @param storage
//! 	An instance of a @[PSYC.Storage] Storage subclass.
//! @seealso
//! 	@[PSYC.Storage.File], @[PSYC.Storage.Remote], @[PSYC.Storage.Dummy]
void create(MMP.Uniform uniform, object server, object storage) {
    
    ::create(uniform, server, storage);
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
	
	if (!context->contains(p->source())) {
	    sendmsg(p->reply(), p->data->reply("_failure_message_public")); 
	}

	parent->castmsg(uni, PSYC.Packet(p->data->mc, 0, p->data->data), p->source());
	return PSYC.Handler.GOON;
    }
}
