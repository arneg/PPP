// vim:syntax=lpc
#include <debug.h>
#include <assert.h>
//inherit PSYC.Storage;
import .module;
#define SET	1
#define GET	2
#define LOCK	4

inherit PSYC.Storage.Base;

//! Basic storage class that operates on a mapping/object.
//! Does locking and request queueing.

mapping(string:array(mixed)) locks = ([ ]);
mapping|object data;

//! @param d
//! 	Mapping or mappinglike object to operate on. Operations on the mapping 
//! 	block, so watch out!
//! @seealso
//! 	@[MappingBased], @[FlatFile]
void create(mapping|object d) {
    enforce(mappingp(d) || objectp(d));
    data = d;
}

//! Save storage (e. g. to disk, depending on the storage class used).
//! @note
//! 	Abstract in this class.
void save();

mixed _get(string key) {
    PT(("Volatile", "_get(%O).\n", key))
    return data[key];
}

void _set(string key, mixed val) {
    data[key] = val;
}

void _lock(string key) {
    PT(("Volatile", "%O: Locking key %s.\n", this, key))

    if (has_index(locks, key)) {
	PT(("Volatile", "%O: Locking already locked key %s.\n", this, key))
	return;
    }

    locks[key] = ({});
}

//! Fetch a variable.
//! @param key
//! 	Name of the variable that should be fetched.
//! @param cb
//!	Callback to be called when the variable has been fetched. Signature: 
//! 	@expr{ void cb(int error, string key, mixed value, mixed ... args)@}.
void get(string key, function cb, mixed ... args) {
    P4(("Volatile", "%O: get(%s, %O, %O)\n", this, key, cb, args))
    assert(functionp(cb));

    if (has_index(locks, key)) {
	PT(("Volatile", "%O: %s is locked. scheduling get.\n", this, key))
	locks[key] += ({ ({ GET, key, cb, args }) });	
	return;
    }

    call_out(cb, 0, OK, key, _get(key), @args);
}

//! Set a variable.
//! @param key
//! 	Name of the variable that should be set.
//! @param value
//! 	The value to set the variable to.
//! @param cb
//! 	Callback to be called when the variable has been set. Signature: 
//! 	@expr{void cb(int error, string key, mixed ... args)@}.
void set(string key, mixed value, function|void cb, mixed ... args) {
    P4(("Volatile", "%O: set(%s, %O, %O, %O)\n", this, key, value, cb, args))

    if (has_index(locks, key)) {
	PT(("Volatile", "%O: %s is locked. scheduling set.\n", this, key))
	locks[key] += ({ ({ SET, key, value, cb, args }) });	
	return;
    }

    _set(key, value);
    if (cb) call_out(cb, 0, OK, key, @args);
}

//! Fetch a set variable and additionally, lock it.
//! @param key
//! 	Name of the variable that should be fetched.
//! @param cb
//!	Callback to be called when the variable has been fetched. Signature:
//! 	@expr{ void cb(int error, string key, mixed value, mixed ... args)@}.
void get_lock(string key, function cb, mixed ... args) {
    P4(("Volatile", "%O: get_lock(%s, %O, %O)\n", this, key, cb, args))

    if (has_index(locks, key)) {
	PT(("Volatile", "%O: %s is locked. scheduling get_lock.\n", this, key))
	locks[key] += ({ ({ GET|LOCK, key, cb, args }) });	
	return;
    }

    _lock(key);
    call_out(cb, 0, OK, key, _get(key), @args);
}

//! Set and lock a variable.
//! @param key
//! 	Name of the variable that should be set.
//! @param value
//! 	The value to set the variable to.
//! @param cb
//! 	Callback to be called when the variable has been set. Signature:
//! 	@expr{void cb(int error, string key, mixed ... args)@}.
void set_lock(string key, mixed value, function|void cb, mixed ... args) {
    P4(("Volatile", "%O: set_lock(%s, %O, %O, %O)\n", this, key, value, cb, args))

    if (has_index(locks, key)) {
	locks[key] += ({ ({ SET|LOCK, key, value, cb, args }) });	
	return;
    }

    _lock(key);
    _set(key, value);
    if (cb) call_out(cb, 0, OK, key, @args);
}

//! Lock a variable.
//! @param key
//! 	Name of the variable that should be locked.
//! @param cb
//! 	Callback to be called when the variable has been locked. Signature:
//! 	@expr{void cb(int error, string key, mixed ... args)@}.
void lock(string key, function|void cb, mixed ... args) {
    P4(("Volatile", "%O: lock(%s, %O, %O)\n", this, key, cb, args))
    
    if (has_index(locks, key)) {
	locks[key] += ({ ({ LOCK, key, cb, args }) });	
	return;
    }

    _lock(key);
    if (cb) call_out(cb, 0, OK, key, @args); 
}


//! Get and unlock a variable.
//! @param key
//! 	Name of the variable that should be fetched.
//! @param cb
//! 	Callback to be called when the variable has been fetched. Signature:
//! 	@expr{void cb(int error, string key, mixed ... args)@}.
void get_unlock(string key, function cb, mixed ... args) {
    P4(("Volatile", "%O: get_unlock(%s, %O, %O)\n", this, key, cb, args))
    call_out(cb, 0, OK, key, _get(key), @args);
    _unlock(key);
}

// no sure when to use that. maybe if we want to be sure that the value we set
// stays there unchanged until we unlock..
//! Set and unlock a variable.
//! @param key
//! 	Name of the variable that should be set.
//! @param value
//! 	The value to set the variable to.
//! @param cb
//! 	Callback to be called when the variable has been set. Signature:
//! 	@expr{void cb(int error, string key, mixed ... args)@}.
void set_unlock(string key, mixed value, function|void cb, mixed ... args) {
    P4(("Volatile", "%O: set_unlock(%s, %O, %O, %O)\n", this, key, value, cb, args))
    if (cb) call_out(cb, 0, OK, key, @args);
    _set(key, value);
    _unlock(key);
}

void _unlock(string key) {
    P4(("Volatile", "%O: Unlocking key %s.\n", this, key))

    if (!has_index(locks, key)) {
	P0(("Volatile", "%O: Trying to unlock %s even though it is _not_ locked!\n", this, key))
	PT(("Volatile", "backtrace: %O\n", describe_backtrace(backtrace())))
	return;
    }

    int num = sizeof(locks[key]);

    foreach (locks[key];int i;array a) {
	int type = a[0];

	switch(type) {
	case GET|LOCK:
	    _lock(a[1]);
	case GET:
	    call_out(a[2], 0, OK, a[1], _get(a[1]), @(a[3]));
	    break;
	case LOCK:
	    _lock(a[1]);
	    call_out(a[2], 0, OK, a[1], @(a[3]));
	    break;
	case SET|LOCK:
	    _lock(a[1]);
	case SET:
	    _set(a[1], a[2]);
	    call_out(a[3], 0, OK, a[1], @(a[4]));
	    break;
	default:
	    P0(("Volatile", "%O: Unknown type (%O) in unroll.\n", this, type))
	}
	
	if (type&LOCK) {
	    if (i == num - 1) { // all done
		m_delete(locks, key);
	    } else {
		locks[key] = locks[key][i+1 ..];	
	    }

	    return;
	}
    }

    m_delete(locks, key);
}

//! Unlock a variable.
//! @param key
//! 	The name of the variable to be unlocked.
//! @param cb
//! 	Callback to be called when the variable has been unlocked. Signature:
//! 	@expr{void cb(int error, string key, mixed ... args)@}.
void unlock(string key, function|void cb, mixed ... args) {
    P4(("Volatile", "%O: unlock(%s, %O, %O)\n", this, key, cb, args))
    _unlock(key);
    if (cb) call_out(cb, 0, OK, key, @args);
}
