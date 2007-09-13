// vim:syntax=lpc
#include <debug.h>

inherit PSYC.Handler.Base;

constant _ = ([ 
    "init" : ([ "lock" : ({ "members" }) ]),
    "filter" : ([
	"" : ({ "members" }),		
    ]),
    "postfilter" : ([
	"_request_members" : ({ "members" }),
    ]),
    "notify" : ([
	"member_left" : ([ "lock" : ({ "members" }) ]),
	"member_entered" : ([ "lock" : ({ "members" }) ]),
    ]),
]);

constant export = ({ "member_remove", "member_insert", "low_member_insert", "low_member_remove" });

void create(mixed ... args) {
    ::create(@args);

    member_insert = parent->storage->wrapped_get_lock(low_member_insert, "members");
    member_remove = parent->storage->wrapped_get_lock(low_member_remove, "members");
}

void init(mapping _v) {
    
    if (!mappingp(_v["members"])) {
	parent->storage->set_unlock("members", ([]));	
    } else {
	parent->storage->unlock("members");
    }

    set_inited(1);
}

//! @decl void member_insert(MMP.Uniform uni)
//! @decl void member_remove(MMP.Uniform uni)
//!
//! Fetches members from storage and calls @[low_member_insert()]/@[low_member_remove()].
//! 
//! @note
//! 	In case you have fetched members already, use @[low_member_insert()]/@[low_member_remove()]
//! 	instead.

//! @decl void low_member_insert(mapping members, MMP.Uniform uni)
//! @decl void low_member_remove(mapping members, MMP.Uniform uni)
//!
//! You should probably use @[member_remove()] or @[member_insert()] unless 
//! you have the @{members} already. Keep in mind that @{members} are expected
//! be locked as we are changing the mapping.
//! 
//! @note 
//! 	Never ever call this method with something other than the locked "members"
//! 	mapping from the storage of the channel.

void low_member_insert(mapping members, MMP.Uniform uni) {
    P0(("Handler.Members", "A NEW MEMBER!! %O \n\n\n", uni))
    members[uni] = 1;
    parent->storage->set_unlock("members", members); 
}

void low_member_remove(mapping members, MMP.Uniform uni) {
    P0(("Handler.Members", "A former MEMBER!! %O \n\n\n", uni))
    m_delete(members, uni);
    parent->storage->set_unlock("members", members); 
}

function member_insert, member_remove;

int filter(MMP.Packet p, mapping _v, mapping _m) {

    if (!mappingp(_v["members"])) {
	P0(("Handler.Members", "%O: 'members' should be a mapping in storage. Dropping Packet.\n", parent))
	return PSYC.Handler.STOP;
    }

    if (!_v["members"][p->source()]) {
	sendmsg(p->reply(), p->data->reply("_error_necessary_membership"));	
	return PSYC.Handler.STOP;
    }

    return PSYC.Handler.GOON;
}

int postfilter_request_members(MMP.Packet p, mapping _v, mapping _m) {
    
    sendmsg(p->reply(), p->data->reply("_status_members", ([ "members" : _v["members"] ])));

    return PSYC.Handler.STOP;
}

void notify_member_entered(mapping _v, MMP.Uniform member) {
    low_member_insert(_v["members"], member);
}

void notify_member_left(mapping _v, MMP.Uniform member) {
    low_member_remove(_v["members"], member);
}
