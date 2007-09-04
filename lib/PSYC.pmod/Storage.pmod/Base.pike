function wrapped_get(function fun, string key, mixed ... args) {
    
    void cb(mixed ... args1) {

	void cb1(int error, string key1, mixed value) {

	    if (error != PSYC.Storage.OK) {
		P0(("PSYC.Storage", "%O: unable to fetch %s.\n", key))
	    }

	    if (key1 == key) {
		fun(value, @args, @args1);
	    } else {
		P0(("PSYC.Storage", "%O: data with wrong name from storage (%O instead of 'members').\n", this, key))
		fun(UNDEFINED);
	    }
	}

	this->get(key, cb1);	
    }

    return cb;
}
