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

void debug(string c, int lvl, string fmt, mixed ... args) {
    if ((has_index(cat, c) && cat[c] >= lvl) || default_lvl >= lvl) {
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

#define COMPL(x)	void compliant_debug##x(string c, mixed ... args) { debug(c, x, @args); } 

COMPL(-1)
COMPL(0)
COMPL(1)
COMPL(2)
COMPL(3)
COMPL(4)
