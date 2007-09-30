// vim:syntax=lpc
#include <debug.h>

inherit PSYC.Handler.Base;

constant _ = ([
    "postfilter" : ([
	"" : 0,
    ]),
    "notify" : ([
	"castmsg" : 0,
    ]),
]);

mapping(MMP.Uniform:object) channels = ([]);

constant export = ({
    "add_channel"
});

void create(object c, function s, MMP.Uniform uni) {
    ::create(c, s, uni);
}

void add_channel(MMP.Uniform channel, object o) {

    if (!functionp(o->msg)) {
	error("BAD BAD handler for channel %O.\n", channel);
    }

    channels[channel] = o;
    parent->create_channel(channel, o->enter, o->leave);
}

int postfilter(MMP.Packet p, mapping _v, mapping _m) {
    MMP.Uniform target = p["_target"];

    if ((target->super||target) == uni) { // paranoid.

	if (has_index(channels, target)) {
	    MMP.Utils.invoke_later(channels[target]->msg, p); 

	    return PSYC.Handler.STOP;
	} else {
	    
	    return PSYC.Handler.GOON;
	}
    } else {
	P0(("ChannelMultiplexer", "packet with wrong target (%O) got here, god knows how.\n", target))	
    }
}

void notify_castmsg(MMP.Packet p, MMP.Uniform channel) {
    if (has_index(channels, channel)) {
	channels[channel]->handle("casted", p);
    }
}

