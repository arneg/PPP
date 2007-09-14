// vim:syntax=lpc
#include <debug.h>

inherit PSYC.Handler.Base;

constant _ = ([ 
    "postfilter" : ([
	"_request_administrators" : 0,
	"_request_add_administrator" : 0,
	"_request_remove_administrator" : 0,
    ]),
    "check" : ([
	"is_admin" : 0,
    ]),
]);

constant export = ({ "is_admin", "get_admin_level", "low_add_admin", "low_remove_admin", "add_admin", "remove_admin" });

void is_admin(MMP.Uniform guy, function callback, mixed ... args) {
    MMP.Utils.invoke_later(callback, 1, @args);
}

void get_admin_level(MMP.Uniform guy, function callback, mixed ... args) {
    MMP.Utils.invoke_later(callback, 1, @args);
}

void check_is_admin(function callback, MMP.Uniform guy) {
    callback(1);
}

// this is used as filter_request_add/remove_administrator aswell, so keep in
// mind when editing.
int postfilter_request_administrators(MMP.Packet p, mapping _v, mapping _m) {

    sendmsg(p->reply(), p->data->reply("_status_channel_administrators", ([ "_admins" : "everyone" ])));

    return PSYC.Handler.STOP;
}

int postfilter_request_add_administrator(MMP.Packet p, mapping _v, mapping _m) {

    sendmsg(p->reply(), p->data->reply("_notice_administrator_added", ([ "_aide" :  p->data["_aide"] ])));
    sendmsg(p->data["_aide"], p->data->reply("_notice_administrator_added", ([ "_aide" :  p->data["_aide"] ])));

    return PSYC.Handler.STOP;
}

int postfilter_request_remove_administrator(MMP.Packet p, mapping _v, mapping _m) {

    sendmsg(p->reply(), p->data->reply("_notice_administrator_removed", ([ "_aide" :  p->data["_aide"] ])));
    sendmsg(p->data["_aide"], p->data->reply("_notice_administrator_removed", ([ "_aide" :  p->data["_aide"] ])));

    return PSYC.Handler.STOP;
}

