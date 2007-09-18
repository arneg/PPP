// vim:syntax=lpc
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
    P3(("Commands", "parse(%O, %O, %O, %O)\n", type, data, ui, args))
    if (intp(type)) switch(type & .Arguments.BEGIN_MODIFIERS) {
    case .Arguments.Integer:
	{
	    array temp;
	    temp = PSYC.Commands.Arguments.Word(data, ui);

	    if (!temp[0]) return temp;

	    if ((string)((int)temp[1]) == temp[1]) {
		temp[1] = (int)temp[1];
		return temp;
	    }

	    return ({ 0, "It's not an Integer, baby." });
	}
    case .Arguments.Uniform:
	{
	    MMP.Uniform u;
	    array temp;
	    temp = PSYC.Commands.Arguments.Word(data, ui);
	    P3(("Commands", "got %O\n", temp))

	    if (!temp[0]) return temp;

	    if (type & .Arguments.Place || (type & (.Arguments.Channel|.Arguments.Person) == .Arguments.Channel)) {
		u = ui->client->room_to_uniform(temp[1]);
	    } else {
		u = ui->client->user_to_uniform(temp[1]);	
	    }

	    if (u) {
		if (type & .Arguments.Channel && !u->channel) {
		    return ({ 0, "The given Uniform is not Channel." });
		}

		return ({ temp[0], u });
	    }

	    return ({ 0, "Exceeds my definition of Uniforms by years "
		         "of science!" });
	}
    } else if (programp(type) || objectp(type)) {
	P3(("Commands", "%O has %O\n", type, indices(type)))
	if (args) {
	    return type(data, ui, @args);	
	} else {
	    return type(data, ui);
	}
    } else {
	THROW(sprintf("Illegal Command definition type %t (%O).\n", type, type));
    }
}

