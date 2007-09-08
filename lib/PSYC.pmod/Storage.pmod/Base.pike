function wrapped_get(function fun, string key, mixed ... args) {
    
    void cb(mixed ... args1) {

	void cb1(int error, string key1, mixed value) {

	    if (error != PSYC.Storage.OK) {
		P0(("PSYC.Storage", "%O: unable to fetch %s.\n", key))
	    }

	    if (key1 == key) {
		fun(value, @args, @args1);
	    } else {
		P0(("PSYC.Storage", "%O: data with wrong name from storage (%O instead of %O).\n", this, key1, key))
		fun(UNDEFINED, @args, @args1);
	    }
	}

	this->get(key, cb1);	
    }

    return cb;
}

function wrapped_get_lock(function fun, string key, mixed ... args) {
    
    void cb(mixed ... args1) {

	void cb1(int error, string key1, mixed value) {

	    if (error != PSYC.Storage.OK) {
		P0(("PSYC.Storage", "%O: unable to fetch %s.\n", key))
	    }

	    if (key1 == key) {
		fun(value, @args, @args1);
	    } else {
		P0(("PSYC.Storage", "%O: data with wrong name from storage (%O instead of %O).\n", this, key1, key))
		fun(UNDEFINED, @args, @args1);
	    }
	}

	this->get_lock(key, cb1);	
    }

    return cb;
}
