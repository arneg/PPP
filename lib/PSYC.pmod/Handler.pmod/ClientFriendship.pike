// vim:syntax=lpc

//! Handler implementing client functionality for friendship establishment.
//! This handler accesses the @expr{peers@} data structure in storage to
//! control the reaction of the Friendship handler inside the @[PSYC.Person].
//! 
//! Having frienship to someone is here equivalent to being subscribed to 
//! someones presence channel.
//! 
//! @seealso
//! 	@[PSYC.Handler.Friendship]

#include <debug.h>
#include <assert.h>

#define OFFERED	1		// offered friendship to 
#define	PENDING 2		// asked for friendship of
#define	ISFRIEND	4	// foobarflags. not needed
#define AMFRIEND	8	// we are his friend

inherit PSYC.Handler.Base;

constant _ = ([
    "_" : ({ "peers" }),
]);

constant export = ({ "unfriend", "unfriend_symmetric", "friend", 
		     "friend_symmetric", "offer", "offer_quiet" });

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
    } else {
	set_inited(1);
    }
}

void general_peer_callback(int error, string key, mixed peers, MMP.Uniform entity, int flag, function callback, mixed args) {
    enforcer(!error, "fetching peers from storage failed.\n");
    enforcer(mappingp(peers), "peers from storage not a mapping.\n");
    enforcer(flag, "flag must be nonzero.\n");

    if (has_index(peers, entity)) {
	mixed spec = peers[entity];

	enforcer(mappingp(spec), "user spec from storage not a mapping.\n");

	int mask = spec["fflags"];

	if ((flags > 0 && mask & flag == 0) || mask & -flag) {
	    if (0 > flag) {
		spec["fflags"] ^= -flag;
	    } else {
		spec["fflags"] |= flag;
	    }
	    parent->storage->set_unlock("peers", peers, callback, @args);
	    return;
	}
    } else if (flag > 0) {
	peers[entity] = ([ "fflags" : flag ]); // we need to set extra default ones here. 
	parent->storage->set_unlock("peers", peers, callback, @args);
	return;
    }
    parent->storage->unlock("peers");
    call_out(callback, 0, 0, @args);
}

//! Cancel friendship to @expr{entity@}.
//! 
//! @note
//! 	This method is not symmetric, therefore @expr{entity@} is not forced to
//! 	leave your friendship channel.
//! @seealso
//! 	@[unfriend_symmetric()]
void unfriend(MMP.Uniform entity) {

    void callback(int error) {
	if (error) {
	    P0(("ClientFriendship", "%O: unfriend(%O) failed.\n", this, entity))
	}

	// leave anyhow.. not sure
	parent->leave(entity);
    };

    parent->storage->get_lock("peers", general_peer_callback, entity, -OFFERED, callback, ({}));
}

//! Cancel friendship to @expr{entity@} and at the same time remove 
//! @expr{entity@} from your presence channel.
void unfriend_symmetric(MMP.Uniform entity) {
    void callback(int error) {
	if (error) {
	    P0(("ClientFriendship", "%O: unfriend(%O) failed.\n", this, entity))
	}

	parent->leave(entity);
	parent->remove(uni, entity);
    };

    parent->storage->get_lock("peers", general_peer_callback, entity, -OFFERED, callback, ({}));
}

//! Request membership in the presence channel of @expr{entity@}.
//! 
//! @note
//! 	This method is not symmetric, therefore @expr{entity@} is not allowed to enter 
//! 	your presence channel.
//! @seealso
//! 	@[friend_symmetric()]
void friend(MMP.Uniform entity) {

    void callback(int error) {
	if (error) {
	    P0(("ClientFriendship", "%O: friend(%O) failed.\n", this, entity))
	} else {
	    // could use the error_cb here to ask again later.. or send an error to the clients.
	    parent->enter(entity);
	}
    };

    parent->storage->get_lock("peers", general_peer_callback, entity, PENDING, callback, ({}));
}

//! Request membership in the presence channel of @expr{entity@} and at the same time grant
//! membership in your own presence channel to @expr{entity@}.
void friend_symmetric(MMP.Uniform entity) {
    enforcer(MMP.is_person(entity), "Rooms dont offer friendship. Thats something else.\n");

    void cb(int error) {
	if (error) {
	    P0(("ClientFriendship", "offer_quiet failed in friend_symmetric(). very bad!!!!!!\n\n"))
	} else {
	    friend(entity);
	}
    };

    offer_quiet(entity, cb);
}

//! Grant membership in your own presence channel to @expr{entity@}.
//! 
//! @note
//! 	This function does not send any notice to @expr{entity@}, use @[offer()] for that.
void offer_quiet(MMP.Uniform entity, void|function callback, mixed ... args) {

    parent->storage->get_lock("peers", general_peer_callback, entity, OFFERED, callback, args);
}

//! Grant membership in your own presence channel to @expr{entity@} and send a
//! @expr{_notice_friendship_offered@} to @expr{entity@}.
void offer(MMP.Uniform entity) {
    void cb(int error) {
	if (error) {
	    P0(("ClientFriendship", "offer_quiet failed in offer(). very bad!!!!!!\n\n"))
	} else {
	    sendmsg(entity, PSYC.Packet("_notice_friendship_offered"));
	}
    };

    offer_quiet(entity, cb);
}
