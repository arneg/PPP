.DebugManager _manager;

//! @returns
//!	A systemwide @[DebugManager] which will be used if you just inherit
//!	@[Public.Logging.PPP.Debug], so you can just use @expr{debug(...)@}
//! 	(documentation: see @[DebugManager()->debug()]
//!	without having to explicitely create a @[DebugManager] for simple
//!	scripts and applications that don't (can) share 'their' VM with other
//!	scripts/applications anyway.
//!
//! @example
//! class X {
//
//! 	inherit Public.Logging.PPP.Debug;
//! 
//! 	void test() {
//!
//! 		debug("info", 0, "i have been called.\n");
//!
//! 		// this is sufficient information because the backtrace
//!
//! 		// will (unless configured otherwise) show from what file,
//!
//!		// function and line the debug message comes from.
//!
//! 	}
//!
//! }
.DebugManager getDefaultManager() {
    if (!_manager) {
	_manager = .DebugManager();
    }

    return _manager;
}
