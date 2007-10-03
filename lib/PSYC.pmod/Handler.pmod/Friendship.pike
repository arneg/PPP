// vim:syntax=lpc

//! A Handler implementing friendship using channels and subscription. It
//! is therefore dependent on both @[PSYC.Handler.Channel] and 
//! @[PSYC.Handler.Subscribe] or equivalent implementations.
//! 
//! The functionality implemented inside this handler is only that needed
//! inside a @[PSYC.Person] or similar objects representing a permanent 
//! adress. Main function is to grant or deny access to the friendship channel
//! based upon per person settings in the @expr{peers@} mapping in storage.

#include <new_assert.h>

#define OFFERED	1		// offered friendship to 
#define	PENDING 2		// asked for friendship of
#define	ISFRIEND	4	// foobarflags. not needed
#define AMFRIEND	8	// we are his friend


inherit PSYC.Handler.Base;

constant _ = ([
    "init" : ({ "peers" }),
    "postfilter" : ([
	"_notice_friendship_offered" : ([ "lock": ({ "peers" }) ]),
    ]),
]);

void create(mapping params) {
    ::create(params);

    parent->create_channel(uni, request_friend, request_unfriend);
}

void init(mapping vars) {
    
    if (!mappingp(vars["peers"])) {
	void callback(int error, string key) {
	    if (error) {
		debug("storage", 0, "Absolutely fatal: initing PSYC.Handler.Friendship failed.\n");
	    } else {
		set_inited(1);
	    }
	};

	parent->storage->set("peers", ([]), callback);
    }
}

int postfilter_notice_friendship_offered(MMP.Packet p, mapping _v, mapping _m) {
    PSYC.Packet m = p->data;
    MMP.Uniform source = p->source();
    mixed peers = _v["peers"];

    if (!mappingp(peers)) {
	parent->storage->unlock("peers");
	do_throw("peers from storage not a mapping.\n");
    }
    
    if (has_index(peers, source)) {
	mixed spec = peers[source];

	if (!mappingp(spec)) {
	    parent->storage->unlock("peers");
	    do_throw("user spec from storage not a mapping.\n");
	}

	if (spec["fflags"] & PENDING) {
	    parent->enter(source);

	    parent->storage->unlock("peers");
	    return PSYC.Handler.STOP;
	}
    }
    
    parent->storage->unlock("peers");
    return PSYC.Handler.GOON;
}

void request_friend(MMP.Uniform guy, function callback, mixed ... args)	{
    debug("friendship", 3, "%O: Friend request from %O.\n", parent, guy);
    
    void cb(int error, string key, mixed peers) {

	if (error != PSYC.Storage.OK) {
	    debug((["storage" : 0, "friendship" : 0 ]), "fetching 'peer' from storage failed.\n");
	    return;
	}

	enforce(mappingp(peers));

	if (has_index(peers, guy)) {
	    mixed spec = peers[guy];

	    if (mappingp(spec) && spec["fflags"] & OFFERED) {
		call_out(callback, 0, 1, @args);
		return;
	    }

	}

	PSYC.Packet r = PSYC.Packet("_request_friendship");
	parent->distribute(MMP.Packet(r, ([ "_source" : guy ]))); 
	call_out(callback, 0, 0, @args);
	// the user may offer again.
    };

    parent->storage->get("peers", cb);
}

void request_unfriend(MMP.Uniform guy) {
    debug("friendship", 3, "%O: %O cancels his friendship.\n", this, guy);
    if (MMP.is_place(guy)) {
	// this is a reason to leave..
	parent->leave(guy);
    }
}
