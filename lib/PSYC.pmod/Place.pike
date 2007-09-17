// vim:syntax=lpc
#include <new_assert.h>

inherit PSYC.Unl;

//! A minimal implementation of a chatroom.

object context;
array history = ({});

//!
//! @param uni
//! 	Uniform of the room.
//! @param server
//! 	A server object providing mmp message delivery.
//! @param storage
//! 	An instance of a @[PSYC.Storage] Storage subclass.
//! @seealso
//! 	@[PSYC.Storage.File], @[PSYC.Storage.Remote], @[PSYC.Storage.Dummy]
void create(mapping params) {
    ::create(params);
    
    mapping handler_params = params + ([ "parent" : this, "sendmmp" : sendmmp ]);

    add_handlers(
		 PSYC.Handler.Channel(handler_params),
		 Public(handler_params),
		 PSYC.Handler.Subscribe(handler_params),
		 );
    this->create_channel(uni, _enter, _leave, _history);
    context = server->get_context(uni);
}


string _sprintf(int type) {
    if (type == 'O') {
	return sprintf("PSYC.Place(%O)", uni);
    }
}

void _enter(MMP.Uniform someone, function callback, mixed ... args) {
    debug("PSYC.Place", 4, "%O: %O asks for membership. args: %O\n", this, someone, args);

    if (MMP.is_person(someone)) {
	
	void _callback(int error, mixed args) {
	    if (error) {
		callback(0, @args);
		debug("PSYC.Place", 0, "%O: %O wont let me join his presence. i therefore wont let him subscribe me.\n", this, someone);
	    } else {
		callback(1, @args); 
		this->castmsg(uni, PSYC.Packet("_notice_context_enter"), someone);
	    }
	};

	this->enter(someone, _callback, args);
    } else {
	debug("PSYC.Place", 0, "Got enter request from non-person %O.\n", someone);
	callback(0, @args);
    }
}

void _leave(MMP.Uniform someone) {
    this->castmsg(uni, PSYC.Packet("_notice_context_leave"), someone);
}

void _history(MMP.Packet p) {
  MMP.Packet entry = p->clone();
  entry->data = entry->data->clone(); // assume psyc packet...
  entry->data->vars->_time_place = time();
  history += ({ entry });
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
