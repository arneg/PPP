// vim:syntax=lpc

inherit PSYC.Handler.Base;

void init_handler() {
    register_incoming(([ "stage" : "postfilter", "method" : Method("") ]));
}

mapping(MMP.Uniform:object) channels = ([]);

constant export = ({
    "add_channel", "get_channel"
});

object get_channel(MMP.Uniform|string chan) {
    if (stringp(chan)) {
	chan = parent->get_uniform(uni+"#"+chan);
    }

    return channels[chan];
}

int has_target(MMP.Packet p) {
    return has_index(p->vars, "_target");
}

void add_channel(MMP.Uniform channel, object o) {

    if (!functionp(o->msg)) {
	error("BAD BAD handler for channel %O.\n", channel);
    }

    channels[channel] = o;
    parent->create_channel(channel, o->enter, o->leave);
}

int prefetch_postfilter(MMP.Packet p, mapping misc) {
    MMP.Uniform target = p["_target"];

    if ((target->super||target) == uni) { // paranoid.

	if (has_index(channels, target)) {
	    MMP.Utils.invoke_later(channels[target]->msg, p); 

	    return PSYC.Handler.STOP;
	} else {
	    
	    return PSYC.Handler.GOON;
	}
    } else {
	debug("ChannelMultiplexer", 2, "packet with wrong target (%O) got here, god knows how.\n", target);	
    }
}
