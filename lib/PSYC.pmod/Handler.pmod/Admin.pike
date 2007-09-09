// vim:syntax=lpc
#include <debug.h>

inherit PSYC.Handler.Base;

constant _ = ([ 
    "" : ([ "lock" : ({ "admins" }) ]),
    "filter" : ([
	"_request_administrators" : ({ "admins" }),
	"_request_add_administrators" : ({ "admins" }),
	"_request_remove_administrators" : ({ "admins" }),
    ]),
    "postfilter" : ([
	"_request_administrators" : ({ "admins" }),
	"_request_add_administrators" : ([ "lock" : ({ "admins" }) ]),
	"_request_remove_administrators" : ([ "lock" : ({ "admins" }) ]),
    ]),
]);

constant export = ({ "is_admin", "get_admin_level", "low_add_admin", "low_remove_admin", "add_admin", "remove_admin" });

function add_admin, remove_admin;

void create(mixed ... args) {
    ::create(@args);

    add_admin = parent->storage->wrapped_get_lock(low_add_admin, "admins");
    remove_admin = parent->storage->wrapped_get_lock(low_remove_admin, "admins");

    is_admin = parent->storage->wrapped_get(low_is_admin, "admins");
    get_admin_level = parent->storage->wrapped_get(low_get_admin_level, "admins");
}

void init(mapping _v) {
    
    if (!mappingp(_v["admins"])) {
	parent->storage->set_unlock("admins", ([]));	
    } else {
	parent->storage->unlock("admins");
    }

    set_inited(1);
}

function is_admin, get_admin_level;

void low_is_admin(mapping admins, MMP.Uniform guy, function callback, mixed ... args) {
    MMP.Utils.invoke_later(callback, has_index(admins, guy), @args);
}

void low_get_admin_level(mapping admins, MMP.Uniform guy, function callback, mixed ... args) {
    MMP.Utils.invoke_later(callback, admins[guy], @args);
}

//! @decl void add_admin(MMP.Uniform uni, int|void level)
//! @decl void remove_admin(MMP.Uniform uni)
//!
//! Fetches admins from storage and calls @[low_add_admin()]/@[low_remove_admin()].
//! 
//! @param level
//! 	Defaults to 1.
//! @note
//! 	In case you have fetched members already, use @[low_add_admin()]/@[low_remove_admin()]
//! 	instead.

//! @decl void low_add_admin(mapping admins, MMP.Uniform uni, int|void level)
//! @decl void low_remove_admin(mapping admins, MMP.Uniform uni)
//!
//! You should probably use @[add_admin()] or @[remove_admin()] unless 
//! you have @{admins} already. Keep in mind that @{admins} are expected
//! be locked as we are changing the mapping.
//! 
//! @note 
//! 	Never ever call this method with something other than the locked "admins"
//! 	mapping from the storage of the channel.

void low_add_admin(mapping members, MMP.Uniform uni, int|void level) {
    members[uni] = zerotype(level) ? 1 : level;
    parent->storage->set_unlock("members", members); 
}

void low_leave(mapping members, MMP.Uniform uni) {
    m_delete(members, uni);
    parent->storage->set_unlock("members", members); 
}

// this is used as filter_request_add/remove_administrator aswell, so keep in
// mind when editing.
int filter_request_administrators(MMP.Packet p, mapping _v, mapping _m) {

    if (!mappingp(_v["admins"])) {
	P0(("PSYC.Handler.Admin", "%O: \"admins\" not a mapping.\n", parent))
	return PSYC.Handler.STOP;
    }

    if (!_v["admins"][p->source()]) {
	sendmsg(p->reply(), p->data->reply("_failure_privileges_necessary"));	
	return PSYC.Handler.STOP;
    }
}

int postfilter_request_administrators(MMP.Packet p, mapping _v, mapping _m) {

    sendmsg(p->reply(), p->data->reply("_status_channel_administrators", ([ "admins" : _v["admins"] ])));

    return PSYC.Handler.STOP;
}

function filter_request_add_administrator = filter_request_administrators;

int postfilter_request_add_administrator(MMP.Packet p, mapping _v, mapping _m) {

    if (!MMP.is_person(p->data["_aide"])) {
	sendmsg("_error_add_administrator_aide");

	return PSYC.Handler.STOP;
    }

    low_add_admin(_v["admins"], p->data["_aide"]);

    sendmsg(p->reply(), p->data->reply("_notice_administrator_added", ([ "_aide" :  p->data["_aide"] ])));
    sendmsg(p->data["_aide"], p->data->reply("_notice_administrator_added", ([ "_aide" :  p->data["_aide"] ])));

    return PSYC.Handler.STOP;
}

function filter_request_remove_administrator = filter_request_administrators;

int postfilter_request_remove_administrator(MMP.Packet p, mapping _v, mapping _m) {

    if (!MMP.is_person(p->data["_aide"])) {
	sendmsg("_error_remove_administrator");

	return PSYC.Handler.STOP;
    }

    low_remove_admin(_v["admins"], p->data["_aide"]);

    sendmsg(p->reply(), p->data->reply("_notice_administrator_removed", ([ "_aide" :  p->data["_aide"] ])));
    sendmsg(p->data["_aide"], p->data->reply("_notice_administrator_removed", ([ "_aide" :  p->data["_aide"] ])));

    return PSYC.Handler.STOP;
}

