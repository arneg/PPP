// vim:syntax=lpc
#include <new_assert.h>

inherit PSYC.Unl;

//! A minimal implementation of a chatroom.

object context;
array history = ({});

//!
//! @param uniform
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
		 PSYC.Handler.Subscribe(handler_params),
		 PSYC.Handler.ChannelMultiplexer(handler_params),
		 PSYC.Handler.ChannelSort(handler_params),
		 PSYC.Handler.AdminEveryone(handler_params), 
		 );
    mapping channel_params = params + ([
		"parent" : this,
		"sendmmp" : sendmmp,
    ]);

    object chan = PSYC.Channel(channel_params);

    mapping channel_handler_params = params + ([
		"parent" chan,
		"sendmmp" : chan->sendmmp,
    ]);

    chan->add_handlers(
		       PSYC.Handler.PublicSymmetric(channel_handler_params),
		       PSYC.Handler.Talk(channel_handler_params),
		       PSYC.Handler.Members(channel_handler_params
		       );
    this->add_channel(uniform, chan);

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


string _sprintf(int type) {
    if (type == 'O') {
	return sprintf("PSYC.Place(%O)", uni);
    }
}
