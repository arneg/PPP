// vim:syntax=lpc
#include <debug.h>
inherit PSYC.Commands.Base;

//! Provides the following commands for setting and retrieving storage variables.
//! @ul
//! 	@item
//!		@expr{"set" . Commands.Word . Commands.String@}
//! 	@item
//!		@expr{"get" . Commands.Word@}
//! @endul

constant _ = ([
    "get" : ({ 
	({ "get", 
	    ({ PSYC.Commands.Word, "key" })
	 }),
    }),
    "set" : ({ 
	({ "set", 
	    ({ PSYC.Commands.Word, "key", 
	       PSYC.Commands.String, "value" }),
	 }),
    }),
]);

void get(string key) {
    P3(("PSYC.Commands.Set", "get(%O)\n", key))
    void cb(string key, mixed value) {
	if (value != UNDEFINED) {
	    parent->display(MMP.Packet(PSYC.Packet("_notice_retrieve", ([ "_key" : key, "_value" : value ]))));
	} else {
	    parent->display(MMP.Packet(PSYC.Packet("_failure_retrieve", ([ "_key" : key ]))));
	}
    };
    parent->storage->get(key, cb); 
}

void set(string key, string value) {
    P3(("PSYC.Commands.Set", "set(%O, %O)\n", key, value))
    //sendmsg(user, PSYC.Packet("_request_store", 0, text)); 
    void cb(int err, string key, string value) {
	if (err == PSYC.Storage.OK) {
	    parent->display(MMP.Packet(PSYC.Packet("_notice_store", ([ "_key" : key, "_value" : value ]))));
	} else {
	    parent->display(MMP.Packet(PSYC.Packet("_failure_store", ([ "_key" : key, "_value" : value ]))));
	}
    };
    parent->storage->set(key, value, cb, value);
    parent->storage->save();
}
