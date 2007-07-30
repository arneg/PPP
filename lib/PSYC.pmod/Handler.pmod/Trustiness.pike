// vim:syntax=lpc
#include <debug.h>
#define MAX_TRUST	9
#define MIN_TRUST	5	// level of trust below nothing really happens
#define NO_TRUST	0
//! Implementation of PSYC remote trust. This module uses the "friends" 
//! variable from storage to find out in whom we trust and in whom we do
//! not trust.
//! Remote trust values are temporary and get lost whenever the Handler 
//! is destructed.
//! 
//! Exports: @[get_trust()]

//! @param friends
//! 	Mapping of friends (from storage).
//! @param guy
//! 	Entity to get trust for.
//! @param trustee
//! 	Trusted authority. Should be a friend of us and @expr{guy@}. 
//! 	@expr{trustee@} is required to have a trust level of @expr{5@} 
//! 	or more to be accepted as an authority.
//! @returns
//! 	An integer value indicating how much we trust in @expr{guy@} with 
//! 	@expr{trustee@} as authority.
//! 	@int
//! 		@value 0
//! 			No trust
//! 		@value 1..4
//! 			...
//! 		@value 5
//! 			Minimal trust required to be trusted authority
//! 			for someone else
//! 		@value 6..8
//! 			...
//! 		@value 9
//! 			Maximum trust
//! 	@endint
int(0..9) get_trust(mapping friends, MMP.Uniform guy, MMP.Uniform|void trustee) {
    int trust;

    if (has_index(friends, guy)) {
	return (int)friends[guy];
    }
    
    if (!trustee || !has_index(friends, trustee)) {
	return NO_TRUST; 
    }

    trust = (int)friends[trustee];

    if (has_index(trusted, trustee) && has_index(trusted[trustee], guy)) {
	return trust * trusted[trustee][guy] / MAX_TRUST;
    }

    return NO_TRUST;
}

inherit PSYC.Handler.Base;


// how much does someone trust others...
// trustee -> guy -> trust
mapping(MMP.Uniform:mapping(MMP.Uniform:int)) trusted = ([]);
mapping(MMP.Uniform:mapping(MMP.Uniform:array(mixed))) pending = ([]);

constant export = ({
    "get_trust"
});

// we have to make a decision whether we keep the trust for ever or not.
constant _ = ([
    "_" : ({ "friends" }),
    "filter" : ([
	"" : ([
	    "async" : 1,
	    "wvars" : ({ "friends" }),
	]),
    ]),
    "postfilter" : ([
	"_request_trustiness" : ({ "friends" }),
	"_notice_trustiness" : ({ "friends" }),
	"_failure_trustiness" : ({ "friends" }),
    ]),
]);

void init(mapping vars) {
    P0(("Trustiness", "Initing trustiness.\n"))
    if (!mappingp(vars["friends"])) {
	void _cb(int err) {
	    if (err) {
		// TODO:: make fatal
		error("could not set friends\n");
	    }

	    set_inited(1);
	};

	parent->storage->set("friends", ([ ]), _cb);
    } else {
	set_inited(1);
    }
}

int postfilter_request_trustiness(MMP.Packet p, mapping _v, mapping _m) {
    PSYC.Packet m = p->data, reply;
    MMP.Uniform source = p->source(), location;
    int trust = 0;

    if (!has_index(m->vars, "_location")) {
	P1(("Handler.Trustiness", "%O: Got _request_trustiness without a _location from %O.\n", parent, source))
	return PSYC.Handler.STOP;
    }

    location = (m->vars["_location"] = m->vars["_location"]);

    if (MIN_TRUST <= get_trust(_v["friends"], source)) {
	trust = get_trust(_v["friends"], location);
	reply = m->reply("_notice_trustiness", ([
					    "_location" : location,
					    "_trustiness" : trust,
						   ]));
    } else {
	reply = m->reply("_failure_trustiness", ([
					    "_location" : location,
						    ]));
    }

    sendmsg(source, reply);

    return PSYC.Handler.STOP;
}

int postfilter_failure_trustiness(MMP.Packet p, mapping _v, mapping _m) {
    PSYC.Packet m = p->data;
    MMP.Uniform location = (m->vars["_location"] = m->vars["_location"]);

    deliver(p->source(), location, NO_TRUST);
    
    return PSYC.Handler.STOP;
}

void process(MMP.Packet reply, mapping _v, MMP.Uniform trustee,
	     MMP.Uniform source) {
    PSYC.Packet m = reply->data;

    P3(("Handler.Trustiness", "%O: process(%O, %O, %O, %O)\n", parent, reply, _v, trustee, source))

    // the tagged variant offers us extra checks.. nothing but
    if (!has_index(m->vars, "_location") ||
	m->vars["_location"] != (string)source ||
	reply->source() != trustee) {
	P1(("Handler.Trustiness", "%O: Got reply with a wrong location (%O instead of %O) to an _request_trustiness (%O) from %O.\n", 
	    parent, m->vars["_location"], source, m, reply->source()))

	// we might think about deleting the pending stuff
	// and GOON the packets without any trust
	deliver(trustee, source, NO_TRUST);	
	return;
    }

    m->vars["_location"] = m->vars["_location"];

    // er....
    if (equal(m->mc / "_", ({ "", "failure", "trustiness" }))) {
	postfilter_failure_trustiness(reply, _v, ([]));
    } else if (equal(m->mc / "_", ({ "", "notice", "trustiness" }))) {
	postfilter_notice_trustiness(reply, _v, ([]));
    }

}

void postfilter_notice_trustiness(MMP.Packet p, mapping _v, mapping _m) {
    PSYC.Packet m = p->data;
    MMP.Uniform trustee = p->source();
    MMP.Uniform location = (m->vars["_location"] = m->vars["_location"]);

    if (!has_index(m->vars, "_trustiness") || !intp(m->vars["_trustiness"])) {
	P1(("Handler.Trustiness", "%O: _notice_trustiness from %O contains strange or no _trustiness (%O).\n", parent, p->source(), m->vars["_trustiness"]))
	deliver(trustee, location, NO_TRUST); 
	return PSYC.Handler.STOP;
    }
    int trust = m->vars["_trustiness"];

    if (!has_index(m->vars, "_location")) {
	P1(("Handler.Trustiness", "%O: _notice_trustiness from %O contains no _location.\n", 
	    parent, p->source()))
	deliver(trustee, location, NO_TRUST); 
	return PSYC.Handler.STOP;
    }

    if (get_trust(_v["friends"], trustee) < MIN_TRUST) {
	P2(("Handler.Trustiness", "%O: Got trustiness for %O from %O (whom we dont trust enough to keep that information).\n", parent, location, trustee))
	deliver(trustee, location, NO_TRUST); 
	return PSYC.Handler.STOP;
    }

    if (!has_index(trusted, trustee)) {
	trusted[trustee] = ([ location : trust ]);
    } else {
	trusted[trustee][location] = trust;
    }

    deliver(trustee, location, get_trust(_v["friends"], location, trustee));

    return PSYC.Handler.STOP;
}

// kicks off all pending packets with trust
void deliver(MMP.Uniform trustee, MMP.Uniform guy, int trust) {

    P3(("Handler.Trustiness", "%O: deliver(%O, %O, %d) from %O.\n", parent, trustee, guy, trust, pending))

    if (has_index(pending, trustee) && has_index(pending[trustee], guy)) {
	foreach (m_delete(pending[trustee], guy);; array ca) {
	    function cb = ca[0];
	    ca[1]["_trust"] = trust;
	    call_out(cb, 0, PSYC.Handler.GOON);
	}
    }
}

void filter(MMP.Packet p, mapping _v, mapping _m, function cb) {
    PSYC.Packet m = p->data;
    int trust = UNDEFINED;
    MMP.Uniform source = p->source();

    // we should change _trust here in any case! later TODO
    if (has_index(_v["friends"], source)) {
	trust = _v["friends"][source];
    } else if (has_index(m->vars, "_trustee")) {
	MMP.Uniform trustee;

	trustee = (m->vars["_trustee"] = m->vars["_trustee"]);

	// everyone has some friends
	if (has_index(trusted, trustee) && has_index(trusted[trustee], source)) {
	    trust = trusted[trustee][source];
	} else if (has_index(pending, trustee) && has_index(pending[trustee], source)) {
	    pending[trustee][source] += ({ cb });
	} else {
	    PSYC.Packet request = PSYC.Packet("_request_trustiness",
					      ([
						"_location" : source,
					       ]));

	    send_tagged_v(trustee, request, 
			       (multiset)_["postfilter"]["_notice_trustiness"], 
			       process, 
			       trustee, source); 

	    if (!has_index(pending, trustee)) {
		pending[trustee] = ([]);
	    }

	    pending[trustee][source] = ({ ({ cb, _m }) });
	}
	return;
    }

    _m["_trust"] = trust;

    call_out(cb, 0, PSYC.Handler.GOON);
}
