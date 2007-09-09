// vim:syntax=lpc
constant Integer 	= 1 << __LINE__;
constant Uniform 	= 1 << __LINE__;
constant BEGIN_MODIFIERS = (1 << __LINE__) - 1;
constant Place 		= 1 << __LINE__;
constant Person		= 1 << __LINE__;
constant Channel	= 1 << __LINE__;
//! Type-constants for Command specifications.
//! @expr{BEGIN_MODIFIERS@} obviously is not a type but a hack. Beware of!
//!
//! It delimits the types @expr{String@}, @expr{Integer@} and @expr{Uniform@}
//! from additional modifiers. Those modifiers may be added to a type in a 
//! bitwise fashion.
//!
//! @int
//! 	@value Integer
//! 		A string consting of a decimal number is expected and will
//! 		be parsed to @expr{int@} accordingly.
//! 	@value Uniform
//! 		A string consting of a uniform is expected and will
//! 		be parsed to @[MMP.Uniform] accordingly. In case of nicknames
//! 		a Uniform defaults to Person.
//! 	@value Place
//! 		A uniform of a Place. Will be parsed as the nickname or
//! 		uniform of a Place and 'return' @[MMP.Uniform].
//! 	@value Person
//! 		A uniform of a Person. Will be parsed as the nickname or
//! 		uniform of a Person and 'return' @[MMP.Uniform].
//! 	@value Channel
//! 		A uniform of a channel. In case of a nickname a Uniform defaults
//! 		to a place if neither Place or Person are chosen.
//! @endint
//! 
//! Additional commands may be implemented using programs. 
//! A few built-in types are:
//! 
//! @int
//! 	@value Word
//! 		Parses a String of non-whitespace characters. Trailing white-spaces are 
//! 		consumed aswell. A fixed length may be specified as an argument.
//! 	@value String
//! 		A string. You may specify a fixed length as an argument, otherwise
//! 		this type will consume the rest of the input.
//! @endint

//! @b{General Information@}
//! 
//! This module is home to the commands, which can be added to
//! @[PSYC.CommandSingleplexer]. In combination, @[PSYC.CommandSingleplexer]
//! and the commands make up the flexible command processing framework.
//! Commands are a convenient and clean way to implement all sorts of client
//! features in a plugin-like way.
//!
//! @b{How to build your own commands, in X steps@}
//! @fixme
//! 	finish howto section
