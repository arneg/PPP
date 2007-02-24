// vim:syntax=lpc
constant String 	= 1 << __LINE__;
constant Integer 	= 1 << __LINE__;
constant Uniform 	= 1 << __LINE__;
constant BEGIN_MODIFIERS = (1 << __LINE__) - 1;
constant Sentence 	= 1 << __LINE__;
constant Place 		= 1 << __LINE__;
constant User 		= 1 << __LINE__;
//! Type-constants for Command specifications.
//! @expr{BEGIN_MODIFIERS@} obviously is not a type but a hack. Beware of!
//!
//! It delimits the types @expr{String@}, @expr{Integer@} and @expr{Uniform@}
//! from additional modifiers. Those modifiers may be added to a type in a 
//! bitwise fashion.
//!
//! @int
//! 	@value String
//! 		A string consisting of non whitespace characters. 
//! 	@value Integer
//! 		A string consting of a decimal number is expected and will
//! 		be parsed to @expr{int@} accordingly.
//! 	@value Uniform
//! 		A string consting of a uniform is expected and will
//! 		be parsed to @[MMP.Uniform] accordingly.
//! 	@value Sentence
//! 		A string consisting of arbitrary characters, e.g. until the end
//!		of the input.
//! 	@value Place
//! 		A uniform of a Place. Will be parsed as the nickname or
//! 		uniform of a Place and 'return' @[MMP.Uniform].
//! 	@value User
//! 		A uniform of a Person. Will be parsed as the nickname or
//! 		uniform of a Person and 'return' @[MMP.Uniform].
//! @endint
//! @fixme
//! 	Rename String to Word and implement true strings (of a certain length).
//! 	Rename User to Person.
// ^^ no comments here! there will be dragons

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

mapping _ = ([ ]);

//! Parse the next argument from the list of arguments. 
//! @param type
//! 	Type of the argument.
//! @param data
//! 	List of arguments.
//! @param ui
//! 	Client object to perform nickname to uniform translations.
//! @returns
//! 	Returns a list consisting of the number of consumed elments in the array,
//!	followed by all parsed arguments.
//! 	In case the given command string does not fit the specification of the
//! 	command, an array consisting of @expr{0@} and an error string is returned. 
//! @fixme
//! 	Start using a string instead of already split arguments in a list.
mixed parse(int type, array(string) data, object ui) {
    switch(type & BEGIN_MODIFIERS) {
    case String:
	if (type & Sentence) {
	    return ({ sizeof(data), data * " " });
	}

	return ({ 1, data[0] });
    case Integer:
	if ((string)((int)data[0]) == data[0]) {
	    return ({ 1, (int)data[0] });
	}

	return ({ 0, "It's not an Integer, baby." });
    case Uniform:
	{
	    MMP.Uniform u;

	    if (type & Place) {
		u = ui->client->room_to_uniform(data[0]);
	    } else {
		u = ui->client->user_to_uniform(data[0]);	
	    }

	    if (u) {
		return ({ 1, u });
	    }

	    return ({ 0, "Exceeds my definition of Uniforms by years "
		         "of science!" });
	}
    }
}

