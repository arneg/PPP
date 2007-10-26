// vim:syntax=lpc

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
    "check" : ([
	"is_member" : ({ "members" }),
    ]),
]);

constant export = ({ "member_remove", "member_insert", "low_member_insert", "low_member_remove" });

void create(mapping params) {
    ::create(params);

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

void check_is_member(mapping _v, function cb, MMP.Uniform guy) {
    cb(has_index(_v["members"], guy));
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
//! you have the @expr{members@} already. Keep in mind that @expr{members@} are expected
//! be locked as we are changing the mapping.
//! 
//! @note 
//! 	Never ever call this method with something other than the locked "members"
//! 	mapping from the storage of the channel.

void low_member_insert(mapping members, MMP.Uniform uni) {
    debug("channel_membership", 2, "A NEW MEMBER!! %O \n\n\n", uni);
    members[uni] = 1;
    parent->storage->set_unlock("members", members); 
    parent->storage->save();
}

void low_member_remove(mapping members, MMP.Uniform uni) {
    debug("channel_membership", 2, "A former MEMBER!! %O \n\n\n", uni);
    m_delete(members, uni);
    parent->storage->set_unlock("members", members); 
}

function member_insert, member_remove;

int filter(MMP.Packet p, mapping _v, mapping _m) {

    if (!mappingp(_v["members"])) {
	debug("channel_membership", 0, "%O: 'members' should be a mapping in storage. Dropping Packet.\n", parent);
	return PSYC.Handler.STOP;
    }

    if (!_v["members"][p->source()]) {
	sendmsg(p->reply(), p->data->reply("_error_necessary_membership"));	
	return PSYC.Handler.STOP;
    }

    return PSYC.Handler.GOON;
}

int postfilter_request_members(MMP.Packet p, mapping _v, mapping _m) {
    PSYC.Packet m = p->data;
    sendmsg(p->reply(), m->reply("_notice_context_members", 
                                   (["_group":uni,
				     "_list_members": indices(_v["members"]),
                                   ])));

    return PSYC.Handler.STOP;
}

void notify_member_entered(mapping _v, MMP.Uniform member) {
    low_member_insert(_v["members"], member);
}

void notify_member_left(mapping _v, MMP.Uniform member) {
    low_member_remove(_v["members"], member);
}
