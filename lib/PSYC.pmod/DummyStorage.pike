#include <debug.h>
inherit PSYC.Storage;

void get(string key, function cb, mixed ... args) {
    mixed value;

    P3(("DummyStorage", "%O: get(%s, %O, %O)\n", this, key, cb, args))

    if (key == "_friends") {
	value = ([]);
    } else {
	value = "test";
    }

    call_out(cb, 0, key, value, @args);  
}
