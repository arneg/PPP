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
]);

constant export = ({ "unfriend", "friend", "offer", "offer_quiet" });

void init(mapping vars) {
    PT(("Handler.ClientFriendship", "Init of %O. vars: %O\n", parent, vars))
    
    if (!mappingp(vars["peers"])) {
	void callback(int error, string key) {
	    if (error) {
		P0(("Handler.ClientSubscribe", "Absolutely fatal: initing handler did not work!!!\n"))
	    } else {
		set_inited(1);
	    }
	};

	parent->storage->set("peers", ([]), callback);
    }
}

void general_peer_callback(string key, mixed peers, MMP.Uniform entity, int flag, function callback, mixed args) {
    enforcer(mappingp(peers), "peers from storage not a mapping.\n");

    if (has_index(peers, entity)) {
	mixed spec = peers[entity];

	enforcer(mappingp(spec), "user spec from storage not a mapping.\n");

	if (spec["fflags"] & flag) { // nullop
	    parent->storage->unlock("peers");
	    call_out(callback, 0, 0, @args);
	    return;
	} else {
	    spec["fflags"] |= flag;
	}
    } else {
	peers[entity] = ([ "fflags" : flag ]); // we need to set extra default ones here. 
    }
    parent->storage->set_unlock("peers", peers, callback, @args);
}

void unfriend(MMP.Uniform entity) {
    parent->leave(entity);
}

void friend(MMP.Uniform entity) {

    void callback(int error) {
	if (error) {
	    P0(("Person", "%O: friend(%O) failed.\n", this, entity))
	} else {
	    // could use the error_cb here to ask again later.. or send an error to the clients.
	    parent->enter(entity);
	}
    };

    parent->storage->get_lock("peers", general_peer_callback, entity, PENDING, callback, ({}));
}

void friend_symmetric(MMP.Uniform entity) {
    enforcer(MMP.is_person(entity), "Rooms dont offer friendship. Thats something else.\n");

    void cb(int error) {
	if (error) {
	    P0(("Person", "offer_quiet failed in friend_symmetric(). very bad!!!!!!\n\n"))
	} else {
	    friend(entity);
	}
    };

    offer_quiet(entity, cb);
}

void offer_quiet(MMP.Uniform entity, void|function callback, mixed ... args) {

    parent->storage->get_lock("peers", general_peer_callback, entity, OFFERED, callback, args);
}

void offer(MMP.Uniform entity) {
    void cb(int error) {
	if (error) {
	    P0(("Person", "offer_quiet failed in offer(). very bad!!!!!!\n\n"))
	} else {
	    sendmsg(entity, PSYC.Packet("_notice_friendship_offered"));
	}
    };

    offer_quiet(entity, cb);
}
