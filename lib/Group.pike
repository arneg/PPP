// vim:syntax=lpc
int silent = 0;

void enter(MMP.Packet, function, function);
int leave(MMP.Packet);
void link(MMP.Packet, function, function);
int unlink(MMP.Packet);
int isMember(MMP.Uniform);

void send(MMP.Uniform, PSYC.Packet);
void castmsg(PSYC.Packet, void|MMP.Uniform);

int msg(MMP.Packet p) {
    MMP.Uniform source = p["_source"];
    PSYC.Packet m = p->data;

    switch (m->mc) {
    case "_request_enter":
    case "_request_enter_join":
    case "_request_group_enter":
	{
	    void _true() {
		send(p->source, m->reply("_echo_enter"));
		if (!silent) {
		    castmsg(PSYC.Packet("_notice_enter", "congratulations, you entered the froup", ([ ])), p->lsource);
		}
	    };

	    void _false() {
		send(source, m->reply("_failure_enter", "forget about it, beavis"));
	    };

	    enter(p, _true, _false);

	    return 1;
	}
    case "_request_leave":
    case "_notice_leave":
	if (leave(p)) {
	    send(source, m->reply("_notice_leave"));

	    if (!silent) {
		castmsg(PSYC.Packet("_notice_place_leave", "[_nick] left.", 
			([ "_nick" : source])));
	    }
	} else {
	    send(source, m->reply("_notice_leave", "the froup doesn't know you anyway."));
	}

	return 1;
    }
    
    return 0;
}
