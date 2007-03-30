// vim:syntax=lpc

constant _ = ([
    "postfilter" : ([
	"_request_do_friend" : ([ 
	    "check" : "has_person",
	    "lvars" : ({ "friends" }),
	]),
	"_request_do_friend_cancel" : ([
	    "check" : "has_person",
	    "lvars" : ({ "friends" }),
	]),
	"_request_do_friend_remove" : ([
	    "check" : "has_person",
	    "lvars" : ({ "friends" }),
	]),
    ]),
]);

int has_person(MMP.Packet p, mapping _m) {
    PSYC.Packet m = p->data;

    if (!_m["itsme"]) {
	sendmsg(p->reply(), m->reply("_notice_failure_friend"));	
	return 0;
    }

    if (!has_index(m->vars, "_person") || !objectp(m["_person"])) {
	sendmsg(p->reply(), m->reply("_notice_failure_friend_missing"));
	return 0;
    }

    return 1;
}

int postfilter_request_do_friend(MMP.Packet p, mapping _v, mapping _m) {
    PSYC.Packet m = p->data;
    MMP.Uniform person = m["_person"];
    mapping friends = _v["friends"];
    mixed degree;
    int current;

    if (!(has_index(m->vars, "_degree") && intp(degree = m["_degree"]) && degree > 0)) {
	degree = 5;
    }
    
    degree = min(degree, 9);

    if (!has_index(friends, person)) {
	friends[person] = -degree;
	current = degree + 1;
    } else {
	current = friends[person];

	if (current < 0) {
	    friends[person] = -degree;
	} else {
	    friends[person] = degree;
	}
    }

    if (abs(current) != degree) {
	storage->set_unlock("friends", friends);
    } else {
	storage->unlock("friends");
    }

    sendmsg(p->reply(), m->reply("_notice_do_friend", ([ "_person" : person, "_degree" : degree ])));
    return PSYC.Handlers.STOP;
}
int postfilter_request_do_friend_cancel(MMP.Packet p, mapping _v, mapping _m) {

}
int postfilter_request_do_friend_remove(MMP.Packet p, mapping _v, mapping _m) {

}
