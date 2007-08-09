mapping(string:int) cat = ([]);
mapping(string:object) stderrs = ([]);
mapping(string:int(0..1)) bt = ([]);

int(0..1) dbt;

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

void set_default_backtrace(int(0..1) i) {
    dbt = i;
}

int(0..1) unset_default_backtrace() {
    int i = dbt;

    dbt = 0;
    return i;
}
int(0..1) get_default_backtrace() {
    return dbt;
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
    } else {
	for (int i = sizeof(a1); i < sizeof(a2); i++) {
	    npath += ({ a2[i] });
	}
    }

    return npath * "/";
}

void debug(string|multiset c, mixed ... args) {
    // lvl, fmt
    string fmt;

    if (multisetp(c)) {
	fmt = args[0];
	args = args[1..];
    } else {
	c = (< ({ c, args[0] }) >);
	fmt = args[1];
	args = args[2..];
    }

    foreach (c; array strct;) {
	string c;
	int lvl;

	[c, lvl] = strct;

	if ((has_index(cat, c) && cat[c] >= lvl) || default_lvl >= lvl) {
	    if (dbt && !has_index(bt, c) || bt[c]) {
		array backtrace = backtrace();
	       
		Pike.BacktraceFrame fun;
		fun = backtrace[-2];

		string nfmt = "%s:%d:%s(";

		array t = ({ "%O" }) * (sizeof(fun) - 3);
		array funargs = ({ });

		nfmt += t * ", " + ")\t";
		fmt = nfmt + fmt;

		for (int i = 3; i < sizeof(fun); i++) {
		    funargs += ({ fun[i] });
		}
		
		string path = diff_paths(getcwd(), fun[0]);
		if (sizeof(path) > sizeof(fun[0])) {
		    path = fun[0];
		}

		args = ({path, fun[1], function_name(fun[2])||"!!!UNKNOWN!!!" }) + funargs + args;

		if (stderrs[c]) {
		    stderrs[c]->write(fmt, @args);
		} else if (default_stderr) {
		    default_stderr->write(fmt, @args);
		} else {
		    werror(fmt, @args);
		}
		return;
	    }
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

    if (dbt && !has_index(bt, c) || bt[c]) {
	trace = backtrace();
	trace = trace[..sizeof(trace) - 2];
    }

    throw(({ s, trace }));
}
