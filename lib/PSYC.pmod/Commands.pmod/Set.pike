// vim:syntax=lpc
#include <debug.h>
inherit PSYC.Commands.Base;

constant _ = ([
    "get" : ({ 
	({ "get", 
	    ({ PSYC.Commands.String, "key" })
	 }),
    }),
    "set" : ({ 
	({ "set", 
	    ({ PSYC.Commands.String, "key", 
	       PSYC.Commands.String|PSYC.Commands.Sentence, "value" }),
	 }),
    }),
]);

void get(string key, array(string) original_args) {
    PT(("PSYC.Commands.Set", "get(%O, %O)\n", key, original_args))
    void cb(string key, mixed value) {
	if (value != UNDEFINED) {
	    parent->display(MMP.Packet(PSYC.Packet("_notice_retrieve", ([ "_key" : key, "_value" : value ]))));
	} else {
	    parent->display(MMP.Packet(PSYC.Packet("_failure_retrieve", ([ "_key" : key ]))));
	}
    };
    parent->storage->get(key, cb); 
}

void set(string key, string value, array(string) original_args) {
    PT(("PSYC.Commands.Set", "set(%O, %O, %O)\n", key, value, original_args))
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
