// vim:syntax=lpc
#include <debug.h>


// generic channel/subscription implementation. should be working ok for:
// * places with different channels
// * presence subscription (also having several channels as different groups in the buddylist)
// * sync notifications for storage.
//
// requirements to channels:
// * subscription by the user

// channel -> member -> urks
// this is temporary.. 
mapping(MMP.Uniform:int) count = ([ ]);

inherit PSYC.Handler.Base;

constant _ = ([
    "postfilter" : ([
	"_request_context_enter" : 0,
	"_request_context_enter_subscribe" : ({ "_members" }),
    ]),
]);

constant export = ({
    "castmsg", "create_channel"
});

int postfilter_request_context_enter(MMP.Packet p, mapping _v, mapping _m) {

    void callback2(int success, PSYC.Packet answer, MMP.Uniform channel, MMP.Uniform guy) {
	void callback1(int error, MMP.Uniform channel, MMP.Uniform guy) {
	    if (error) {
		sendmsg(guy, PSYC.Packet("_error_context_enter"));
		return;
	    }

	    //sendmsg(guy, PSYC.Packet("_notice_place_enter"));
	    castmsg(channel, PSYC.Packet("_notice_place_enter"), guy);
	};

	if (success) {
	    uni->server->get_context(channel)->insert(guy, callback1, channel, guy);
	} else {
	    if (!answer) answer = PSYC.Packet("_failure_context_enter");
	    sendmsg(guy, answer);
	}
    };
	
    uni->add(guy, callback2, p["_target"], p->source());
    return PSYC.Handler.STOP;
}

int postfilter_request_context_enter_subscribe(MMP.Packet p, mapping _v, mapping _m) {



    return PSYC.Handler.STOP;
}


int create_channel(MMP.Uniform channel) {
    
    if (channel->channel) {
	if (channel->super != uni->uni) {
	    return 0;
	}

    } else if (channel != uni->uni) {
	return 0;
    }

    if (!has_index(count, channel)) {
	count[channel] = 0;
    }
}

void castmsg(MMP.Uniform channel, PSYC.Packet m, MMP.Uniform source_relay) {

    if (!has_index(count, channel)) {
	THROW("trying to cast on an nonexistent channel\n");
    }

    MMP.Packet p = MMP.Packet(m, ([ "_context" : channel, 
				    "_source_relay" : source_relay,
				    "_count" : count[channel]++,
				    ]))
    uni->server->get_context(channel)->msg(p); 
}
