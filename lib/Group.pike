
inherit Uni;

multiset groupies = (< >);
int silent = 0;

int(0..1) isMember(mixed kerl) {
    return groupies[kerl];
}

int msg(MMP.mmp_p p) {

    if (::msg(p)) return 1;
    
    string|PSYC.uniform source = p["_source"];
    PSYC.psyc_p m = p->data;

    switch (m->mc) {
    case "_request_enter":
    case "_request_group_enter":
	groupies[(string)source] = 1;
	if (silent) 
	    sendmsg(source, "_echo_group_enter");
	else
	    castmsg("_notice_group_enter", "", ([ ]));
	    // castmsg means sendmsg with _context only??? makes much sense to
	    // me ..
	return 1;
    case "_request_leave":
	sendmsg(source, "_notice_leave");
    case "_notice_leave":
	if (!silent && isMember((string)source)) {
	    castmsg("_notice_group_leave", "[_nick] left.", 
		    ([ "_nick" : source]));
	}
	groupies[(string)source] = 0;
	return 1;
    }
    
    return 0;
}

void castmsg(string mc, string data, mapping(string:string) vars) {
    PSYC.psyc_p packet = PSYC.psyc_p(mc, data, vars);

    foreach (indices(groupies), string kerl) {
	// good thing: caching is done inside p
	send(kerl, packet);
    }
}
