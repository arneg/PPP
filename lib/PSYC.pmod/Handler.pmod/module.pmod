//! @b{General Information@}
//! 
//! This module is home to the handlers, which can be added to
//! @[PSYC.MethodMultiplexer]. In combination, @[PSYC.MethodMultiplexer]
//! and the handlers make up the flexible PSYC processing framework.
//! Handlers are a convenient and clean way to implement all sorts of PSYC
//! features in a plugin-like way.
//!
//! @b{How to build your own modules, in X steps@}
//! @fixme
//! 	finish howto section


//! Constant for telling the @[PSYC.MethodMultiplexer] framework to go on with
//! processing the packet.
constant GOON = 1;

//! Constant for telling the @[PSYC.MethodMultiplexer] framework to stop
//! processing.
constant STOP = 0;

//! Constant for telling the @[PSYC.MethodMultiplexer] framework to pass on
//! the packet to the display handler without further processing.
constant DISPLAY = 2;
