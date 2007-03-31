// vim:syntax=lpc
#include <debug.h>
#include <assert.h>

#define OFFERED	1		// offered friendship to 
#define	PENDING 2		// asked for friendship of
#define	ISFRIEND	4	// foobarflags. dont needed
#define AMFRIEND	8	// we are his friend

inherit PSYC.Handler.Base;

constant _ = ([
    "_" : ({ "peers" }),
    "postfilter" : ([
	"_notice_friendship_offered" : ([ "lock": ({ "peers" }) ]),
    ]),
]);

void create(object o, function f, object u) {
    ::create(o,f,u);

    parent->create_channel(u, request_friend, request_unfriend);
}

void init(mapping vars) {
    PT(("Handler.Friendship", "Init of %O. vars: %O\n", parent, vars))
    
    if (!mappingp(vars["peers"])) {
	void callback(int error, string key) {
	    if (error) {
		P0(("Handler.Friendship", "Absolutely fatal: initing handler did not work!!!\n"))
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
	enforcer(0, "peers from storage not a mapping.\n");
    }
    
    if (has_index(peers, source)) {
	mixed spec = peers[source];

	if (!mappingp(spec)) {
	    parent->storage->unlock("peers");
	    enforcer(0, "user spec from storage not a mapping.\n");
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
    PT(("Handler.Friendship", "%O: Friend request from %O.\n", parent, guy))
    
    void cb(int error, string key, mixed peers) {

	if (error != PSYC.Storage.OK) {
	    P0(("Handler.Friendship", "fetching the peer-data failed.\n"))
	    return;
	}

	PT(("Handler.Friendship", "peer data structure: %O\n", peers))
	PT(("Handler.Friendship", "extra args: %O\n", args))

	if (has_index(peers, guy)) {
	    enforcer(mappingp(peers), "peers from storage not a mapping.\n");

	    if (has_index(peers, guy)) {
		mixed spec = peers[guy];

		enforcer(mappingp(spec), "user spec from storage not a mapping.\n");

		if (spec["fflags"] & OFFERED) { // nullop
		    call_out(callback, 0, 1, @args);
		    return;
		}
	    }
	    call_out(callback, 0, 0, @args);
	}

	PSYC.Packet r = PSYC.Packet("_request_friendship");
	parent->distribute(MMP.Packet(r, ([ "_source" : guy ]))); 
	call_out(callback, 0, 0, @args);
	// the user may offer again.
    };

    parent->storage->get("peers", cb);
}

void request_unfriend(MMP.Uniform guy) {
    PT(("Person", "%O: %O removes his friendship.\n", this, guy))  
}
