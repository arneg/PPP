//! This class can be inherited so that debug and do_throw
//! (from @[DebugManager]) can be directly used while the DebugManager
//! can still be exchanged.

// yes, technically we don't really need this reference here, but it might
// come in handy in the future
#if constant(Public.Logging.PPP)
.DebugManager _debugmanager = Public.Logging.PPP.getDefaultManager();
#else
.DebugManager _debugmanager;
#endif

//! @decl void do_throw(string fmt, mixed ... args)
//! See @[DebugManager()->do_throw()]

//! @decl void debug(string category, int level, string fmt, mixed ... args)
//! @decl void debug(mapping(string:int) cats, string fmt, mixed ... args)
//! See @[DebugManager()->debug()]

// so the backtrace won't get messed up
#if constant(Public.Logging.PPP)
function debug = Public.Logging.PPP.getDefaultManager()->debug;
function do_throw = Public.Logging.PPP.getDefaultManager()->do_throw;
#else
function debug;
function do_throw;
#endif

//! @param s
//! 	The @[DebugManager] this object reports to.
//!
//!	If Public.Logging.PPP is present (it usually is, when you installed
//!	it from/by monger, and might be not if this class is shipped to you
//!	for example by the @i{ppp@} and you don't have installed
//!	Public.Logging.PPP via monger, a VM-global default @[DebugManager]
//!	will be used, obtainable by calling
//!	@[Public.Logging.PPP.getDefaultManager()]. In that case,
//!	@expr{create()@} may not be called at all (if you inherit this class
//!	and overload @expr{create()@}), or with an empty argument list, which
//!	will both lead to the default @[DebugManager] being used.
void create(.DebugManager|void s) {
    if (!(_debugmanager = s)) {
#if !constant(Public.Logging.PPP)
	throw(({ "No DebugManager given.\n", backtrace() }));
#else
	return;
#endif
    }

    debug = s->debug;
    do_throw = s->do_throw;
}
