// vim:syntax=lpc
#include <debug.h>

//! Constants for the success argument to storage callbacks.
constant OK = 0;
constant ERROR = 1;
constant TEMP_ERROR = 2;
constant PERMANENT_ERROR = 3;

void multifetch(object storage, multiset locked_vars, multiset vars, function callback, function fail, mixed ... args) {
    P3(("Storage", "multifetch(%O, %O, %O, %O, %O, %O)\n", storage, locked_vars, vars, callback, fail, args))

    void fetched(int error, string key, mixed value, multiset locked_vars, multiset vars, mapping(string:mixed) new, function callback, function fail, mixed args) {

	P3(("Storage", "fetched(%O, %O,%O,%O,%O,%O,%O,%O)\n", error, key, value, locked_vars, vars, new, callback, args))

	if (error) {
	    THROW(sprintf("fetching %O failed in multifetch.\n", key));
	}
		
	if (has_index(new, key)) {
	    THROW(sprintf("key %O received twice. duh.\n", key));
	}

	if (!(locked_vars && has_index(locked_vars, key) || vars && has_index(vars, key))) {
	    THROW(sprintf("some bozo sent us key %O, but we didn't request that. punish him!\n", key));
	}

	new[key] = value;

	if (sizeof(new) == (locked_vars && sizeof(locked_vars)) + (vars && sizeof(vars))) {
	    call_out(callback, 0, new, @args);
	}
    };

    mapping(string:mixed) new = ([]);
    int isclown = 1;

    if (locked_vars) foreach (locked_vars; string key;) {
	isclown = 0;
	storage->get_lock(key, fetched, locked_vars, vars, new, callback, fail, args);
    }

    if (vars) foreach (vars; string key;) {
	isclown = 0;
	storage->get(key, fetched, locked_vars, vars, new, callback, fail, args);
    }

    if (isclown) {
	call_out(callback, 0, new, @args);
    }
}

