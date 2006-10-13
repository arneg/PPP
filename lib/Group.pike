// vim:syntax=lpc
int silent = 0;

void enter(MMP.Packet, function, function);
int leave(MMP.Packet);
void link(MMP.Packet, function, function);
int unlink(MMP.Packet);
int isMember(MMP.Uniform);

void sendmsg(MMP.Uniform, PSYC.Packet);
void kast(MMP.Packet, void|MMP.Uniform);
void castmsg(MMP.Packet);

int msg(MMP.Packet p) {
    MMP.Uniform source = p["_source"];
    PSYC.Packet m = p->data;

    switch (m->mc) {
    case "_request_enter":
    case "_request_enter_join":
    case "_request_group_enter":
	{
	    void _true() {
		sendmsg(p->source(), m->reply("_echo_enter", "You entered [_source]."));
		if (!silent) {
		    kast(PSYC.Packet("_notice_enter", "congratulations, [_nick] entered the froup", ([ "_nick" : p->lsource() ])));
		}
	    };

	    void _false() {
		sendmsg(source, m->reply("_failure_enter", "forget about it, beavis"));
	    };

	    enter(p, _true, _false);

	    return 1;
	}
    case "_request_leave":
    case "_notice_leave":
	if (leave(p)) {
	    sendmsg(source, m->reply("_notice_leave"));

	    if (!silent) {
		kast(PSYC.Packet("_notice_place_leave", 
			         "[_nick] left.",
			         ([ "_nick" : source])));
	    }
	} else {
	    sendmsg(source, m->reply("_notice_leave", "the froup doesn't know you anyway."));
	}

	return 1;
    }
    
    return 0;
}
