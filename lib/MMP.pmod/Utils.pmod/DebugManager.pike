//! Debug/Log class. Per category levels can be set when to display/log a
//! debug output or not. Fully configurable at runtime so that there is no
//! need to restart the application/service in order to hunt down issues.
//!
//! @b{How the levels / categories work@} @xml{<br />@}
//!	Every message has to be assigned a category, and a level.
//!	If the level of the message is lower or equal than the debug level
//!	configured for the category, the message will be printed/logged,
//!	otherwise discarded.
//!
//! @example
//!DebugManager d = DebugManager();
//!d->debug("my category", 5, "this message will be discarded, "
//!+ "because default debug level is 0.\n");
//!d->debug("another category", 0, "this will be printed for "
//!+ "obvious reasons!\n");
//!d->set_debug("warn", 5); // print messags from the warn
//!			    // category up to level 5.
//!d->debug("warn", 2, "this will be printed, too.\n");
//!
//! @note
//!	Do not inherit this class in order to get easy access to @[debug()]
//!	and @[do_throw()]. See "See also"!
//!
//! @seealso
//!	@[Debug] for a class that can be inherited and then provides easy
//!	access to @[debug()] and @[do_throw()] while the @[DebugManager]
//!	can still be exchanged.

mapping(string:int) cat = ([]);
mapping(string:object) stderrs = ([]);
mapping(string:int) bt = ([]);

int dbt;

int default_lvl = 0;
object default_stderr;
// categories of debug -> their current levels
//

//! Sets the default debug level which is used for categories for which no
//! specific level is set.
//!
//! @seealso
//!	@[set_debug()], @[get_default_debug()]
void set_default_debug(int lvl) {
    default_lvl = lvl;
}

//! @returns
//!	The current default debug level.
//!
//! @seealso
//!	@[set_default_debug()], @[get_debug()]
int get_default_debug() {
    return default_lvl;
}

//! Sets the default "stderr object" to which the output is written to.
//! Because the only expectation towards "stderr objects" is that they provide
//! a @expr{->write(string fmt, mixed ... args)@} (which is expected to
//! render the message like @[sprintf()] would) this can be anything from a
//! @[Stdio.File] over a file appender to a syslog wrapper.
//!
//! @b{If a message belongs to multiple categories, the message will be only
//! printed once for every distinctive "stderr object"@}.
//! @example
//!DebugManager dm = DebugManager();
//!dm->debug(([ "dogs" : 0, "cats" : 0]), "this will be printed only "
//!          + "once\n");
//!dm->set_stderr("cats", Stdio.stdout);
//!dm->debug(([ "dogs" : 0, "cats" : 0]), "this will be printed twice, "
//!          + "once on stderr, once on stdout.\n");
//!
//! @seealso
//!	@[set_stderr()]
void set_default_stderr(object o) {
    default_stderr = o;
}

//! Sets the default backtrace level. Messages that will be printed will
//! include a "backtrace" consisting of the file, line number, function
//! (and the arguments to that function) from which the message originates
//! if their level is lower or equal to the backtrace level they are subjected
//! to (default or category specific backtrace level).
//!
//! @seealso
//!	@[set_backtrace()], @[get_default_backtrace()],
//!	@[unset_default_backtrace()]
void set_default_backtrace(int i) {
    dbt = i;
}

//! Unsets the default backtrace level.
//!
//! @returns
//!	The current default backtrace level
//!
//! @seealso
//!	@[unset_backtrace()], @[set_default_backtrace()],
//!	@[get_default_backtrace()]
int unset_default_backtrace() {
    int i = dbt;

    dbt = 0;
    return i;
}

//! Unsets the default debug level.
//!
//! @returns
//!	The current default debug level.
//!
//! @seealso
//!	@[unset_debug()], @[set_default_debug()], @[get_default_debug()]
int unset_default_debug() {
    int i = default_lvl;

    default_lvl = 0;
    return i;
}

//! @returns
//!	The current default backtrace level.
//!
//! @seealso
//!	@[set_default_backtrace()], @[unset_default_backtrace()],
//!	@[get_backtrace()]
int get_default_backtrace() {
    return dbt;
}

//! Unsets the default stderr object.
//!
//! @returns
//!	The default stderr object currently set.
//!
//! @note
//!	This will not return @[Stdio.stderr] if none is set (although that
//!	is where in that case messages are printed to).
//!
//! @seealso
//!	@[unset_stderr()], @[set_default_stderr()], @[get_default_stderr()]
object unset_default_stderr() {
    object t = default_stderr;

    default_stderr = 0;
    return t;
}

//! @returns
//!	The default stderr object currently set.
//!
//! @note
//!	This will not return @[Stdio.stderr] if none is set (although that
//!	is where in that case messages are printed to).
//!
//! @seealso
//!	@[get_stderr()], @[set_default_stderr()], @[unset_default_stderr()]
object get_default_stderr() {
    return default_stderr;
}

//! Sets the debug level for a specific category.
//!
//! @seealso
//!	@[set_default_debug()], @[get_debug()], @[unset_debug()] and especially
//!	@[DebugManager] for an explanation of how the levels work.
void set_debug(string category, int lvl) {
    cat[category] = lvl;
}

//! Unsets the debug level for a specific category.
//!
//! @returns
//!	The level for the given category currently set.
//!
//! @seealso
//!	@[set_debug()], @[get_debug()], @[unset_default_debug()]
int unset_debug(string category) {
    return m_delete(cat, category);
}

//! @returns
//!	The level for the given category currently set.
//!
//! @seealso
//!	@[set_debug()], @[unset_debug()], @[get_default_debug()]
int get_debug(string category) {
    return cat[category];
}

//! Sets the "stderr object" for the given category.
//!
//! @seealso
//!	@[get_stderr()], @[unset_stderr()] and especially
//!	@[set_default_stderr()] for an explanation which kind of objects
//!	can be used as a "stderr object".
void set_stderr(string category, object o) {
    stderrs[category] = o; 
}

//! Unsets the "stderr object" for the given category.
//!
//! @returns
//!	The "stderr object" for the given category currently set.
//!
//! @seealso
//!	@[set_stderr()], @[get_stderr()], @[unset_default_stderr()]
object unset_stderr(string category) {
    return m_delete(stderrs, category);
}

//! @returns
//!	The "stderr object" for the given category currently set.
//!
//! @seealso
//!	@[set_stderr()], @[unset_stderr()], @[get_default_stderr()]
object get_stderr(string category) {
    return stderrs[category]; 
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

//! @decl void debug(string cat, int level, string fmt, mixed ... args)
//! @decl void debug(mapping(string:int) cats, string fmt, mixed ... args)
//! Debug-/log-messages are passed to this function, which then decides
//! whether they should be printed or not according to the categories and
//! levels given, and the configuration of the @[DebugManager].
//!
//! @param cat
//! @param cats
//! @param level
//!	@expr{cat@} is the category a message belongs to, and @expr{level@}
//!	is the level of the message (higher leveled messages are less
//!	important, see also @[DebugManager] for a description of how levels
//!	work).
//!
//!	@expr{cats@} is just a mapping of @expr{cat : level@} pairs, so you
//!	can supply that if you want your message to belong to multiple
//!	categories.
//! @param fmt
//!	Format string (think @[sprintf()]).
//! @param args
//!	Additional parameters to be inserted into the message as directed
//!	by the format string.
//!
//! @example
//!DebugManager dm = DebugManager();
//!dm->debug("warn", 2, "Some not too important warning in object %O\n", this);
//!dm->debug("info", 0, "Got called\n");
//!dm->debug(([ "mail" : 1, "info" : 3 ]), "A mail from %s arrived.\n",
//!          mail->get_from()); // belongs to different categories with
//!                             // different levels.
//!
//! @seealso
//!	@[set_default_debug()], @[set_debug()], @[set_default_backtrace()],
//!	@[set_backtrace()], @[do_throw()]

void debug(string|mapping(string:int) cats, mixed ... args) {
    // lvl, fmt
    string fmt, all_cats, bt_fmt;
    array bt_args, left_args;
    mapping seen = ([ ]), scheduled = ([ ]);

    if (mappingp(cats)) {
	fmt = args[0];
	args = args[1..];
    } else {
	cats = ([ cats : args[0] ]);
	fmt = args[1];
	args = args[2..];
    }

    foreach (cats; string c; int lvl) {
	int(0..1) want_bt;
	string tmp_fmt;
	array tmp_args;

	if ((has_index(cat, c) && cat[c] >= lvl) || default_lvl >= lvl) {
	    if (!left_args) {
		left_args = ({ all_cats || (all_cats = sprintf("%O(%d)", indices(cats)[*], values(cats)[*]) * ", ") });
	    }

	    if ((dbt >= lvl && !has_index(bt, c)) || (has_index(bt, c) && bt[c] >= lvl)) {
		want_bt = 1;
		if (!bt_fmt) {
		    array backtrace = backtrace();
		   
		    Pike.BacktraceFrame fun;
		    fun = backtrace[-2];

		    string nfmt = "%s:%d:%s(";

		    array t = ({ "%O" }) * (sizeof(fun) - 3);
		    array funargs = ({ });

		    nfmt += t * ", " + ")\t";
		    bt_fmt = nfmt + fmt;

		    for (int i = 3; i < sizeof(fun); i++) {
			funargs += ({ fun[i] });
		    }
		    
		    string path = diff_paths(getcwd(), fun[0]);
		    if (sizeof(path) > sizeof(fun[0])) {
			path = fun[0];
		    }

		    bt_args = ({  path, fun[1], function_name(fun[2])||"!!!UNKNOWN!!!" }) + funargs + args;

		    bt_fmt = "[%s]:" + bt_fmt;
		}

		tmp_fmt = bt_fmt;
		tmp_args = left_args + bt_args;
	    } else {
		tmp_fmt = "[%s]\t" + fmt;
		tmp_args = left_args + args;
	    }

	    object out = stderrs[c] || default_stderr || Stdio.stderr;

	    if (seen[out] < (want_bt + 1)) {
		// we need a trampoline here, because otherwise (at least in
		// pike 7.6.86) tmp_fmt and tmp_args from the very last loop
		// run are used inside the lambda...
		function _get_write(object out, string tmp_fmt,
				    array tmp_args) {
		    void _f() {
			out->write(tmp_fmt, @tmp_args);
		    };

		    return _f;
		};

		scheduled[out] = _get_write(out, tmp_fmt, tmp_args);
	    }
	}
    }

    values(scheduled)();
}

//! Sets the backtrace level for a specific category.
//!
//! @seealso
//!	@[set_default_backtrace()] for an explanation of what backtraces are
//!	in this context, @[get_backtrace()] and @[unset_backtrace()]
void set_backtrace(string category, int trace) {
    bt[category] = trace;
}

//! Unsets the backtrace level for a specific category.
//!
//! @returns
//!	The backtrace level for the given category currently set.
//!
//! @seealso
//!	@[set_backtrace()], @[get_backtrace()], @[unset_default_backtrace()]
int unset_backtrace(string category) {
    return m_delete(bt, category);
}

//! @returns
//!	The backtrace level for the given category currently set.
//!
//! @seealso
//!	@[set_backtrace()], @[unset_backtrace()], @[get_default_backtrace()]
int get_backtrace(string c) {
    return bt[c];
}

//! This function is a wrapper to @[throw()] that will render the exception
//! message using @expr{sprintf(fmt, @@args)@} and include a backtrace if (and
//! only if) either the default backtrace level or the backtrace level for
//! the category "exception" is 0 or higher.
//!
//! So you can disable backtraces by
//! @example
//!	debugmanager->set_backtrace("exception", -1);
void do_throw(string fmt, mixed ... args) {
    string s = sprintf(fmt, @args);
    string c = "exception";
    array trace;

    
    if (dbt >= 0 && !has_index(bt, c) || bt[c] >= 0) {
	trace = backtrace();
	trace = trace[..sizeof(trace) - 2];
    }

    throw(({ s, trace }));
}
