// vim:syntax=lpc
constant Integer 	= 1 << __LINE__;
constant Uniform 	= 1 << __LINE__;
constant BEGIN_MODIFIERS = (1 << __LINE__) - 1;
constant Place 		= 1 << __LINE__;
constant Person		= 1 << __LINE__;
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
//! 		be parsed to @[MMP.Uniform] accordingly.
//! 	@value Place
//! 		A uniform of a Place. Will be parsed as the nickname or
//! 		uniform of a Place and 'return' @[MMP.Uniform].
//! 	@value Person
//! 		A uniform of a Person. Will be parsed as the nickname or
//! 		uniform of a Person and 'return' @[MMP.Uniform].
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

#include <debug.h>

//! Parse the next argument from the list of arguments. 
//! @param type
//! 	Type of the argument.
//! @param data
//! 	String starting with the next argument of type @expr{type@}.
//! @param ui
//! 	Client object to perform nickname to uniform translations.
//! @returns
//! 	Returns a list consisting of the number of consumed characters in the input,
//!	followed by all parsed arguments.
//! 	In case the given command string does not fit the specification of the
//! 	command, an array consisting of @expr{0@} and an error string is returned. 
array parse(int|object|program type, string data, object ui, void|array(mixed) args) {
    PT(("Commands", "parse(%O, %O, %O, %O)\n", type, data, ui, args))
    if (intp(type)) switch(type & BEGIN_MODIFIERS) {
    case Integer:
	{
	    array temp;
	    temp = PSYC.Commands.Word(data, ui);

	    if (!temp[0]) return temp;

	    if ((string)((int)temp[1]) == temp[1]) {
		temp[1] = (int)temp[1];
		return temp;
	    }

	    return ({ 0, "It's not an Integer, baby." });
	}
    case Uniform:
	{
	    MMP.Uniform u;
	    array temp;
	    temp = PSYC.Commands.Word(data, ui);
	    PT(("Commands", "got %O\n", temp))

	    if (!temp[0]) return temp;

	    if (type & Place) {
		u = ui->client->room_to_uniform(temp[1]);
	    } else {
		u = ui->client->user_to_uniform(temp[1]);	
	    }

	    if (u) {
		return ({ temp[0], u });
	    }

	    return ({ 0, "Exceeds my definition of Uniforms by years "
		         "of science!" });
	}
    } else if (programp(type) || objectp(type)) {
	PT(("Commands", "%O has %O\n", type, indices(type)))
	if (args) {
	    return type(data, ui, @args);	
	} else {
	    return type(data, ui);
	}
    } else {
	THROW(sprintf("Illegal Command definition type %t (%O).\n", type, type));
    }
}

