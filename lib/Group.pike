
inherit Uni;

// lets use a mapping and allow classes inheriting Group to store data to that
// mapping(string:mapping(mixed:mixed))
multiset groupies = (< >);
// uniform -> route
multiset routes = (< >);
// route -> num of members
int silent = 0;

int(0..1) isMember(mixed kerl) {
    return groupies[kerl];
}

int msg(MMP.mmp_p p) {

    if (::msg(p)) return 1;
    
    string|MMP.uniform source = p["_source"];
    PSYC.psyc_p m = p->data;

    switch (m->mc) {
    case "_request_enter":
    case "_request_enter_join":
    case "_request_group_enter":
	groupies[(string)source] = 1;
	if (silent) 
	    sendmsg(source, "_echo_place_enter");
	else
	    castmsg("_notice_place_enter", "congratulations, you entered the group", ([ ]));
	    // castmsg means sendmsg with _context only??? makes much sense to
	    // me ..
	return 1;
    case "_request_leave":
	sendmsg(source, "_notice_leave");
    case "_notice_leave":
	if (!silent && isMember((string)source)) {
	    castmsg("_notice_place_leave", "[_nick] left.", 
		    ([ "_nick" : source]));
	}
	groupies[(string)source] = 0;
	return 1;
    }
    
    return 0;
}

void sendmsg(string|MMP.uniform target, string mc, string|void data, mapping(string:mixed)|void vars) {
    if (!vars) 
	vars = ([ ]);
    vars["_nick_place"] = this->uni; 
    ::sendmsg(target, mc, data, vars);
}

void castmsg(string mc, string data, mapping(string:string) vars) {
    PSYC.psyc_p packet = PSYC.psyc_p(mc, data, vars);

    packet["_context"] = this->uni;
    vars["_nick_place"] = this->uni; 
    foreach (indices(groupies), string kerl) {
	// good thing: caching is done inside p
	// this is totally borked.. all of it.
	// this is totally borked.. all of it.
	// this is totally borked.. all of it.
	// this is totally borked.. all of it.
	// this is totally borked.. all of it.
	// this is totally borked.. all of it.
	// this is totally borked.. all of it.
	// this is totally borked.. all of it.
	// this is totally borked.. all of it.
	send(kerl, packet);
    }
}
