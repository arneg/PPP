//! This class can be inherited so that debug and do_throw
//! (from @[DebugManager]) can be directly used while the DebugManager
//! can still be exchanged.

.DebugManager _debugmanager;

//! @decl void do_throw(string fmt, mixed ... args)
//! See @[DebugMananger()->do_throw()]

//! @decl void debug(string category, int level, string fmt, mixed ... args)
//! @decl void debug(mapping(string:int) cats, string fmt, mixed ... args)
//! See @[DebugManager()->debug()]

// so the backtrace won't get messed up
function debug;
function do_throw;

//! @param s
//! 	The @[DebugManager] this object reports to.
void create(.DebugManager s) {
    if (!(_debugmanager = s)) {
	throw(({ "No DebugManager given.\n", backtrace() }));
    }

    debug = s->debug;
    do_throw = s->do_throw;
}
