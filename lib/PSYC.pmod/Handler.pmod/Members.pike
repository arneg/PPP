// vim:syntax=lpc
#include <debug.h>

inherit PSYC.Handler.Base;

constant _ = ([ 
    
]);

constant export = ({ "leave", "enter", "members" });

void enter() {
    
}

void leave() {

}

//! Callback will be called with the mapping of members as the first argument, or UNDEFINED on error.
void members(function callback) {
    
    void cb(int error, string key, mapping members) {

	if (error != PSYC.Storage.OK) {
	    P0(("PSYC.Members", "unable to fetch members.\n"))
	}

	if (key == "members") {
	    callback(members);
	} else {
	    P0(("Handler.Members", "data with wrong name from storage (%O instead of 'members').\n", key))
	    callback(UNDEFINED);
	}
    }

    storage->get("members", cb); 
}
