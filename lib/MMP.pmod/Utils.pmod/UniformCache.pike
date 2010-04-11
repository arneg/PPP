    mapping(string:MMP.Uniform) c = ([]);

    MMP.Uniform get_uniform(string s) {
	if (!has_index(c, s)) {
	    c[s] = MMP.Uniform(s);
	}

	return c[s];
    }
