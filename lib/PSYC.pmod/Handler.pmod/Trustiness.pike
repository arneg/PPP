// vim:syntax=lpc
#include <debug.h>
#define MAX_TRUST	9
#define MIN_TRUST	5	// level of trust below nothing really happens
#define NO_TRUST	0

/* TODO: fix the _friends mapping, not to use strings for the uniforms
 * 	 anymore.. that sux noodles..
 */

int get_trust(mapping friends, MMP.Uniform guy, MMP.Uniform|void trustee) {
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
mapping(MMP.Uniform:mapping(MMP.Uniform:array(function))) pending = ([]);

// we have to make a decision whether we keep the trust for ever or not.
constant _ = ([
    "filter" : ([
	"" : ([
	    "async" : 1,
	    "wvars" : ({ "_friends" }),
	]),
    ]),
    "postfilter" : ([
	"_request_trustiness" : ({ "_friends" }),
	"_notice_trustiness" : ({ "_friends" }),
	"_failure_trustiness" : ({ "_friends" }),
    ]),
]);

int postfilter_request_trustiness(MMP.Packet p, mapping _v) {
    PSYC.Packet m = p->data, reply;
    MMP.Uniform source = p->source(), location;
    int trust;

    if (!has_index(m->vars, "_location")) {
	P1(("Handler.Trustiness", "%O: Got _request_trustiness without a _location from %O.\n", uni, source))
	return PSYC.Handler.STOP;
    }

    location = (m->vars["_location"] = string2uniform(m->vars["_location"]));

    if (MIN_TRUST <= get_trust(_v["_friends"], source)) {
	trust = get_trust(_v["_friends"], location);
	reply = m->reply("_notice_trustiness", 0, ([
					    "_location" : location,
					    "_trustiness" : trust,
						   ]));
    } else {
	reply = m->reply("_failure_trustiness", 0, ([
					    "_location" : location,
						    ]));
    }

    return PSYC.Handler.STOP;
}

int postfilter_failure_trustiness(MMP.Packet p, mapping _v) {
    PSYC.Packet m = p->data;
    MMP.Uniform location = (m->vars["_location"] = string2uniform(m->vars["_location"]));

    deliver(p->source(), location, NO_TRUST);
    
    return PSYC.Handler.STOP;
}

void process(MMP.Packet reply, mapping _v, MMP.Uniform trustee, 
	     MMP.Uniform source) {
    PSYC.Packet m = reply->data;

    // the tagged variant offers us extra checks.. nothing but
    if (!has_index(m->vars, "_location") ||
	m->vars["_location"] != (string)source ||
	reply[source] != trustee) {
	P1(("Handler.Trustiness", "%O: Got reply with a wrong location to an _request_trustiness (%O) from %O.\n", uni, m, reply->source()))

	// we might think about deleting the pending stuff
	// and GOON the packets without any trust
	deliver(trustee, source, NO_TRUST);	
	return;
    }

    m->vars["_location"] = string2uniform(m->vars["_location"]);

    // er....
    if (equal(m->mc / "_", ({ "", "failure", "trustiness" }))) {
	postfilter_failure_trustiness(reply, _v);
    } else if (equal(m->mc / "_", ({ "", "notice", "trustiness" }))) {
	postfilter_notice_trustiness(reply, _v);
    }

}

void postfilter_notice_trustiness(MMP.Packet p, mapping _v) {
    PSYC.Packet m = p->data;
    MMP.Uniform trustee = p->source();
    MMP.Uniform location = (m->vars["_location"] = string2uniform(m->vars["_location"]));

    if (!has_index(m->vars, "_trustiness") || !intp(m->vars["_trustiness"])) {
	P1(("Handler.Trustiness", "%O: _notice_trustiness from %O contains strange or no _trustiness (%O).\n", uni, p->source(), m->vars["_trustiness"]))
	deliver(trustee, location, NO_TRUST); 
	return PSYC.Handler.STOP;
    }
    int trust = m->vars["_trustiness"];

    if (!has_index(m->vars, "_location")) {
	P1(("Handler.Trustiness", "%O: _notice_trustiness from %O contains no _location.\n", 
	    uni, p->source()))
	deliver(trustee, location, NO_TRUST); 
	return PSYC.Handler.STOP;
    }



    if (get_trust(_v["_friends"], trustee) < MIN_TRUST) {
	P2(("Handler.Trustiness", "%O: Got trustiness for %O from %O (whom we dont trust enough to keep that information).\n", uni, location, trustee))
	deliver(trustee, location, NO_TRUST); 
	return PSYC.Handler.STOP;
    }

    if (!has_index(trusted, trustee)) {
	trusted[trustee] = ([ location : trust ]);
    } else {
	trusted[trustee][location] = trust;
    }

    deliver(trustee, location, get_trust(_v["_friends"], location, trustee));

    return PSYC.Handler.STOP;
}

// kicks off all pending packets with trust
void deliver(MMP.Uniform trustee, MMP.Uniform guy, int trust) {

    if (has_index(pending, trustee) && has_index(pending[trustee], guy)) {
	foreach (m_delete(pending[trustee], guy);; function cb) {
	    call_out(cb, 0, PSYC.Handler.GOON);
	}
    }
}

void filter(MMP.Packet p, mapping _v, function cb) {
    PSYC.Packet m = p->data;

    // we should change _trust here in any case! later TODO
    if (has_index(m->vars, "_trustee")) {
	int trust = UNDEFINED;
	MMP.Uniform trustee, source = p->source();

	trustee = (m->vars["_trustee"] = string2uniform(m->vars["_trustee"]));

	// everyone has some friends
	if (has_index(_v["_friends"], source)) {
	    trust = _v["_friends"][source];
	} else if (has_index(trusted, trustee) && has_index(trusted[trustee], source)) {
	    trust = trusted[trustee][source];
	} else if (has_index(pending, trustee) && has_index(pending[trustee], source)) {
	    pending[trustee][source] += ({ cb });
	} else {
	    PSYC.Packet request = PSYC.Packet("_request_trustiness", 0, 
					      ([
						"_identification" : source,
					       ]));

	    uni->send_tagged_v(request, process, 
			       _["postfilter"]["_notice_trustiness"], 
			       trustee, source); 
	}
	return;
    }

    PT(("Handler.Trustiness", "%O: leaving filter-stage.\n", uni))
    call_out(cb, 0, PSYC.Handler.GOON);
}