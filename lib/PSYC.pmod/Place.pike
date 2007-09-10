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

// not working here..
void _history(MMP.Packet p) {
  MMP.Packet entry = p->clone();
  entry->data = entry->data->clone(); // assume psyc packet...
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
		 PSYC.Handler.Subscribe(this, sendmmp, uniform),
		 PSYC.Handler.ChannelMultiplexer(this, sendmmp, uniform),
		 );
    context = server->get_context(uniform);

    object default_chan = PSYC.Channel(([
		"storage" : storage,
		"parent" : this,
		"sendmmp" : sendmmp,
		"uniform" : uniform,
    ]));

    default_chan->add_handlers(
			       PSYC.Handler.PublicSymmetric(default_chan, default_chan->sendmmp, uniform),
			       PSYC.Handler.Talk(default_chan, default_chan->sendmmp, uniform), 
			       );

    this->add_channel(uniform, default_chan);
}

void add(MMP.Uniform guy, function cb, mixed ... args) {
    call_out(cb, 0, @args);
}
