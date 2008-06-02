array container;                                                                                         
void create(array a) {
    container = a;
}

int(0..1) `==(mixed arg) {
    if (objectp(arg)) {                                          
	if (Program.inherits(object_program(arg), this_program)) {
	    return equal(container, arg->container);
	}
    }
}

// TODO:: more efficient hash function!
int __hash() {
    if (!container) {
	return hash_value(container);
    }
							   
    int ret;                                                     
    foreach (container;int i;mixed val) {
	int t = hash_value(val);
	ret ^= (t * (i + 1)) % Int.NATIVE_MAX;
    }
    return ret;
}
