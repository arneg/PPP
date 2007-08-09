mapping(string:int) cat = ([]);
mapping(string:object) stderrs = ([]);
mapping(string:int(0..1)) bt = ([]);

int default_lvl = 0;
object default_stderr;
// categories of debug -> their current levels
//

void set_default_debug(int lvl) {
    default_lvl = lvl;
}

int get_default_debug() {
    return default_lvl;
}

void set_default_stderr(object o) {
    default_stderr = o;
}

object unset_default_stderr() {
    object t = default_stderr;

    default_stderr = 0;
    return t;
}

object get_default_stderr() {
    return default_stderr;
}

void set_debug(string c, int lvl) {
    cat[c] = lvl;
    werror("%O %O %O\n", cat, c, lvl);
}

int unset_debug(string c) {
    return m_delete(cat, c);
}

int get_debug(string c) {
    return cat[c];
}

void set_stderr(string c, object o) {
    stderrs[c] = o; 
}

object unset_stderr(string c) {
    return m_delete(stderrs, c);
}

object get_stderr(string c) {
    return stderrs[c]; 
}

string diff_paths(string f1, string f2) {
    array a1 = f1 / "/"; 
    array a2 = f2 / "/"; 
    array npath = ({ });
    int i;

    for (i = 0; i < min(sizeof(a1), sizeof(a2)); i++) {
	 if (a1[i] == a2[i]) {
	 } else {
	    npath += ({ ".." }) * (min(sizeof(a1), sizeof(a2)) - i);
	    break;
	 }
    }

    if (sizeof(a1) > sizeof(a2)) {
	for (int i = sizeof(a2); i < sizeof(a1); i++) {
	    npath += ({ ".." });
	}
	npath += ({ a2[-1] });
    } else {
	npath += ({ a2[i] });
	for (int i = sizeof(a1); i < sizeof(a2); i++) {
	    npath += ({ a2[i] });
	}
    }

    return npath * "/";
}

void debug(string c, int lvl, string fmt, mixed ... args) {
    if ((has_index(cat, c) && cat[c] >= lvl) || default_lvl >= lvl) {
	if (bt[c]) {
	    array backtrace = backtrace();
	   
	    Pike.BacktraceFrame debug, fun;
	    debug = backtrace[-1];
	    fun = backtrace[-2];

	    string nfmt = "%s:%d:%s(";

	    array t = ({ "%O" }) * (sizeof(fun) - 3);
	    array funargs = ({ });

	    nfmt += t * ", " + ")\t";
	    fmt = nfmt + fmt;

	    for (int i = 3; i < sizeof(fun); i++) {
		funargs += ({ fun[i] });
	    }
	    
	    string path = diff_paths(getcwd(), debug[0]);
	    if (sizeof(path) > sizeof(debug[0])) {
		path = debug[0];
	    }

	    args = ({path, debug[1], function_name(fun[2])||"!!!UNKNOWN!!!" }) + funargs + args;
	}

	if (stderrs[c]) {
	    stderrs[c]->write(fmt, @args);
	} else if (default_stderr) {
	    default_stderr->write(fmt, @args);
	} else {
	    werror(fmt, @args);
	}
    }
}

void set_backtrace(string c, int(0..1) trace) {
    bt[c] = trace;
}

int(0..1) unset_backtrace(string c) {
    return m_delete(bt, c);
}

int(0..1) get_backtrace(string c) {
    return bt[c];
}

void do_throw(string c, string fmt, mixed ... args) {
    string s = sprintf(fmt, @args);
    array trace;

    if (bt[c]) {
	trace = backtrace();
	trace = trace[..sizeof(trace) - 2];
    }

    throw(({ s, trace }));
}
