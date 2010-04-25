    mapping(string:MMP.Uniform) uniform_cache = ([]);

    MMP.Uniform get_uniform(string s) {
	if (!has_index(uniform_cache, s)) {
	    uniform_cache[s] = MMP.Uniform(s);
	}

	return uniform_cache[s];
    }
