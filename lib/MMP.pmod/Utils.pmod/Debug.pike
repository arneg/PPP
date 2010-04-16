//! This class can be inherited so that debug and do_throw
//! (from @[DebugManager]) can be directly used while the DebugManager
//! can still be exchanged.

// yes, technically we don't really need this reference here, but it might
// come in handy in the future

//! @decl void do_throw(string fmt, mixed ... args)
//! See @[DebugManager()->do_throw()]

//! @decl void debug(string category, int level, string fmt, mixed ... args)
//! @decl void debug(mapping(string:int) cats, string fmt, mixed ... args)
//! See @[DebugManager()->debug()]

// so the backtrace won't get messed up
#if constant(Public.Logging.PPP)
.DebugManager _debugmanager = Public.Logging.PPP.get_default_manager();
void debug(mixed ... args) {
    _debugmanager->debug(@args);
}
#else
void debug(mixed ... args) {}
#endif

//! @param s
//! 	The @[DebugManager] this object reports to.
//!
//!	If Public.Logging.PPP is present (it usually is, when you installed
//!	it from/by monger, and might be not if this class is shipped to you
//!	for example by the @i{ppp@} and you don't have installed
//!	Public.Logging.PPP via monger, a VM-global default @[DebugManager]
//!	will be used, obtainable by calling
//!	@[Public.Logging.PPP.get_default_manager()]. In that case,
//!	@expr{create()@} may not be called at all (if you inherit this class
//!	and overload @expr{create()@}), or with an empty argument list, which
//!	will both lead to the default @[DebugManager] being used.
void create(.DebugManager|void s) {
#if constant(Public.Logging.PPP)
    if (s) _debugmanager = s;
#endif
}

#if constant(Public.Logging.PPP)
# define P(n) 	void P##n(string module, string fmt, mixed ... args) { _debugmanager->debug(module, fmt, @args); }
#else
# define P(n) 	void P##n(string module, string fmt, mixed ... args) { werror("%s: %s", module, sprintf(fmt, @args)); }
#endif
#define D(n) 	void P##n(string module, string fmt, mixed ... args) {}

#ifdef DEBUG
P(0)
# if DEBUG > 0
P(1)
# else
D(1)
# endif
# if DEBUG > 1
P(2)
# else
D(2)
# endif
# if DEBUG > 2
P(3)
# else
D(3)
# endif
# if DEBUG > 3
P(4)
# else
D(4)
# endif
#else
D(0) D(1) D(2) D(3) D(4)
#endif

