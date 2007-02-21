// vim:syntax=lpc
#include <debug.h>
#include <assert.h>
//inherit PSYC.Storage;
import .module;
#define SET	1
#define GET	2
#define LOCK	4

mapping(string:array(mixed)) locks = ([ ]);
mixed data;

void create(mixed d) {
    assert(mappingp(d) || objectp(d));
    data = d;
}

mixed _get(string key) {
    return data[key];
}

void _set(string key, mixed val) {
    data[key] = val;
}

void _lock(string key) {
    
    if (has_index(locks, key)) {
	P0(("Volatile", "%O: Locking already locked key %s.\n", this, key))
	return;
    }

    locks[key] = ({});
}

void get(string key, function cb, mixed ... args) {
    P3(("Volatile", "%O: get(%s, %O, %O)\n", this, key, cb, args))

    if (has_index(locks, key)) {
	P0(("Volatile", "%O: %s is locked. scheduling get.\n", this, key))
	locks[key] += ({ ({ GET, key, cb, args }) });	
	return;
    }

    call_out(cb, 0, key, _get(key), @args);
}

void set(string key, mixed value, function|void cb, mixed ... args) {
    P3(("Volatile", "%O: set(%s, %O, %O, %O)\n", this, key, value, cb, args))

    if (has_index(locks, key)) {
	locks[key] += ({ ({ SET, key, value, cb, args }) });	
	return;
    }

    _set(key, value);
    if (cb) call_out(cb, 0, OK, key, @args);
}

void get_lock(string key, function cb, mixed ... args) {
    P3(("Volatile", "%O: get_lock(%s, %O, %O)\n", this, key, cb, args))

    if (has_index(locks, key)) {
	P0(("Volatile", "%O: %s is locked. scheduling get_lock.\n", this, key))
	locks[key] += ({ ({ GET|LOCK, key, cb, args }) });	
	return;
    }

    _lock(key);
    call_out(cb, 0, key, _get(key), @args);
}

void set_lock(string key, mixed value, function|void cb, mixed ... args) {
    P3(("Volatile", "%O: set_lock(%s, %O, %O, %O)\n", this, key, value, cb, args))

    if (has_index(locks, key)) {
	locks[key] += ({ ({ SET|LOCK, key, value, cb, args }) });	
	return;
    }

    _lock(key);
    _set(key, value);
    if (cb) call_out(cb, 0, OK, key, @args);
}

void lock(string key, function|void cb, mixed ... args) {
    P3(("Volatile", "%O: lock(%s, %O, %O)\n", this, key, cb, args))
    
    if (has_index(locks, key)) {
	locks[key] += ({ ({ LOCK, key, cb, args }) });	
	return;
    }

    _lock(key);
    if (cb) call_out(cb, 0, OK, key, @args); 
}


void get_unlock(string key, function cb, mixed ... args) {
    P3(("Volatile", "%O: get_unlock(%s, %O, %O)\n", this, key, cb, args))
    call_out(cb, 0, key, _get(key), @args);
    _unlock(key);
}

// no sure when to use that. maybe if we want to be sure that the value we stored
// stays there unchanged until we unlock..
void set_unlock(string key, mixed value, function|void cb, mixed ... args) {
    P3(("Volatile", "%O: set_unlock(%s, %O, %O, %O)\n", this, key, value, cb, args))
    if (cb) call_out(cb, 0, OK, key, @args);
    _set(key, value);
    _unlock(key);
}

void _unlock(string key) {

    if (!has_index(locks, key)) {
	P0(("Volatile", "%O: Trying to unlock %s even though it is _not_ locked!\n", this, key))
    }

    int num = sizeof(locks[key]);

    foreach (locks[key];int i;array a) {
	int type = a[0];

	if (type&GET) {
	    call_out(a[2], 0, a[1], _get(a[1]), @(a[3]));
	} else if (type&SET) {
	    _set(a[1], a[2]);
	    call_out(a[3], 0, OK, a[1], @(a[4]));
	} else if (type&LOCK) {
	    call_out(a[2], 0, OK, a[1], @(a[3]));
	} else {
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

void unlock(string key, function|void cb, mixed ... args) {
    P3(("Volatile", "%O: unlock(%s, %O, %O)\n", this, key, cb, args))
    _unlock(key);
    if (cb) call_out(cb, 0, OK, key, @args);
}
