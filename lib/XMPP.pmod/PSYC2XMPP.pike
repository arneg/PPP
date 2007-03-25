/*
 * transform PSYC to XMPP - most of the time this will be calling the textdb
 */
#include <debug.h>

string transform(MMP.Packet packet) {
    string from, to;
    mixed source, target;
    PSYC.Packet p = packet->data;

#if 0
    source = packet->source();
    target = packet["_target"];

    from = source->user || source->resource[1..];
    from+= "@" + source->host;

    to = target->user;
    to+= "@" + target->host;

    switch(p->mc) {
    case "_message_private":
	return "<message from='" + from + "' to='" + to + "'>" 
		+ "<body>" + p->data + "</body></message>";
	    break;
    default:
	PT(("PSYC2XMPP", "mc %O not handled.\n", p->mc))
    }
#endif
    return "";
}

