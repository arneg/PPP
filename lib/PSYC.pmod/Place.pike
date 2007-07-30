// vim:syntax=lpc
#include <debug.h>
#include <assert.h>

inherit PSYC.Unl;
//! A minimal implementation of a chatroom.

object context;
array history = ({});

string _sprintf(int type) {
    if (type == 'O') {
	return sprintf("PSYC.Place(%O)", uni);
    }
}

void _enter(MMP.Uniform someone, function callback, mixed ... args) {
    PT(("Place", "%O: %O asks for membership. args: %O\n", this, someone, args))

    if (MMP.is_person(someone)) {
	
	void _callback(int error, mixed args) {
	    if (error) {
		callback(0, @args);
		P0(("Place", "%O: %O wont let me join his presence. i therefore wont let him subscribe me.\n", this, someone))
	    } else {
		callback(1, @args); 
		this->castmsg(uni, PSYC.Packet("_notice_context_enter"), someone);
	    }
	};

	this->enter(someone, _callback, args);
    } else {
	P0(("Place", "Got enter request from non-person %O.\n", someone))
	callback(0, @args);
    }
}

void _leave(MMP.Uniform someone) {
    this->castmsg(uni, PSYC.Packet("_notice_context_leave"), someone);
}

void _history(MMP.Packet p) {
  MMP.Packet entry = p->clone();
  entry->data->vars->_time_place = time();
  history += ({ entry });
}

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
    add_handlers(
		 PSYC.Handler.Channel(this, sendmmp, uniform),
		 Public(this, sendmmp, uniform),
		 PSYC.Handler.Subscribe(this, sendmmp, uniform),
		 );
    this->create_channel(uniform, _enter, _leave, _history);
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
	
	if (!parent->context->contains(p->source())) {
	    sendmsg(p->reply(), p->data->reply("_failure_message_public")); 
	}

	parent->castmsg(uni, PSYC.Packet(p->data->mc, 0, p->data->data), p->source());
	return PSYC.Handler.GOON;
    }
}
