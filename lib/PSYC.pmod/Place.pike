// vim:syntax=lpc
#include <debug.h>
#include <assert.h>

inherit PSYC.Unl;
//! A minimal implementation of a chatroom.

string _sprintf(int type) {
    if (type == 'O') {
	return sprintf("PSYC.Place(%O)", uni);
    }
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
		 PSYC.Handler.ChannelSort(this, sendmmp, uniform),
		 PSYC.Handler.AdminEveryone(this, sendmmp, uniform), 
		 );
    object default_chan = PSYC.Channel(([
		"storage" : storage,
		"parent" : this,
		"sendmmp" : sendmmp,
		"uniform" : uniform,
    ]));

    default_chan->add_handlers(
			       PSYC.Handler.PublicSymmetric(default_chan, default_chan->sendmmp, uniform),
			       PSYC.Handler.Talk(default_chan, default_chan->sendmmp, uniform), 
			       PSYC.Handler.Members(default_chan, default_chan->sendmmp, uniform), 
			       PSYC.Handler.History(default_chan, default_chan->sendmmp, uniform),
			       );
    this->add_channel(uniform, default_chan);

    MMP.Uniform test_chan_uni = server->get_uniform((string)uniform+"#test");
    object test_chan = PSYC.Channel(([
		"storage" : server->get_storage(test_chan_uni),
		"parent" : this,
		"sendmmp" : sendmmp,
		"uniform" : test_chan_uni,
    ]));
    test_chan->add_handlers(
			   PSYC.Handler.Public(test_chan, test_chan->sendmmp, uniform),
			   PSYC.Handler.Talk(test_chan, test_chan->sendmmp, uniform), 
			   PSYC.Handler.Members(test_chan, test_chan->sendmmp, uniform), 
			   );

    this->add_channel(test_chan_uni, test_chan);
}

void add(MMP.Uniform guy, function cb, mixed ... args) {
    call_out(cb, 0, @args);
}
