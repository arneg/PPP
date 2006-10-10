inherit PSYC.Storage;

void get(string key, function cb, mixed ... args) {
    call_out(cb, 0, key, key*2, @args);  
}
