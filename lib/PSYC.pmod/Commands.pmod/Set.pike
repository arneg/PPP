// vim:syntax=lpc
#include <debug.h>
inherit PSYC.Commands.Base;

//! Provides the following commands for setting and retrieving storage variables.
//! @ul
//! 	@item
//!		@expr{"set" . PSYC.Commands.Arguments.Word . PSYC.Commands.Arguments.String@}
//! 	@item
//!		@expr{"get" . PSYC.Commands.Arguments.Word@}
//! @endul

constant _ = ([
    "get" : ({ 
	({ "get", 
	    ({ PSYC.Commands.Arguments.Word, "key" })
	 }),
    }),
    "set" : ({ 
	({ "set", 
	    ({ PSYC.Commands.Arguments.Word, "key", 
	       PSYC.Commands.Arguments.String, "value" }),
	 }),
    }),
]);

void get(string key) {
    P3(("PSYC.Commands.Set", "get(%O)\n", key))
    void cb(int error, string key, mixed value) {
	if (error == PSYC.Storage.OK) {
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
