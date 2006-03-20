
multiset groupies = (< >);

int(0..1) isMember(mixed kerl) {
    return groupies[kerl];
}

int msg(psyc_p m) {
    switch (m->mc) {
    case "_request_enter":
    case "_request_group_enter":
	groupies[m["_source"]] = 1;
	if (silent) 
	    sendmsg(m["_source"], "_echo_group_enter");
	else
	    castmsg("_notice_group_enter", "", ([ ]));
	break;
    case "_request_leave":
	sendmsg(m["_source"], "_notice_leave");
    case "_notice_leave":
	groupies[m["_source"]] = 0;
	break;
    }
    
}


