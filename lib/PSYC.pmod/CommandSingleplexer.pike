// vim:syntax=lpc
#include <debug.h>

//! This provides a neat framework for working with user commands.
//! Even has storage support. You'll like it!

mapping commands = ([ ]);

//! Adds command handler(s) to the 'environment'.
//! @param args
//! 	The command handlers to add.
void add_commands(PSYC.Commands.Base ... args) {
    
    foreach(args;;PSYC.Commands.Base handler) {
	foreach(handler->_;string command; array dings) {
	    array fix_dings(array old_dings) {
		array new_dings = allocate(sizeof(old_dings));

		for (int i = 0; i < sizeof(old_dings); i++) {
		    new_dings[i] = old_dings[i] + ({ });
		    new_dings[i][0] = `->(handler, new_dings[i][0]);
		}

		return new_dings;
	    };


	    if (has_index(commands, command)) {
		commands[command] += fix_dings(dings);
	    } else {
		commands[command] = fix_dings(dings);
	    }
	}
    }
}

//! Entry point for command parsing.
//! @param input
//! 	The command the user entered, but without "command chars", like a
//! 	preceeding slash.
void cmd(string input) {
    P3(("PSYC.CommandSingleplexer", "cmd(%O)\n", input))
    int i;

    i = search(input, ' ');

    string command, args;

    if (i == -1) {
	args = "";
	command = input;
    } else {
	command = input[0 .. i-1];
	while (sizeof(input) > i && input[++i] == ' ');
	args = input[i ..];
    }
	

    if (has_index(commands, command)) {
COMMAND: foreach (commands[command];;array pair) {
	    function fun;
	    array specs;
	    int i = 1;
	    mixed results = ({ });

	    [fun, specs] = pair;

	    foreach (specs/2;; array spec) {
		int stat;
		string name;
		mixed result, type;

		[type, name] = spec;

		if (sizeof(args) <= i) {
		    P1(("PSYC.CommandSingleplexer", "sizeof(args)(==%O) <= %O\n", sizeof(args), i))
		    break COMMAND;
		}
		
		if (arrayp(type)) {
		    [stat, result] = PSYC.Commands.parse(type[0], args[i..], this, type[1..]);
		} else {
		    [stat, result] = PSYC.Commands.parse(type, args[i..], this);
		} 

		if (stat == 0) {
		    P1(("PSYC.CommandSingleplexer", "a parse(%O) failed, hooray.\n", type))
		    break COMMAND;
		}

		i += stat;
		results += ({ result });
	    }

	    P1(("PSYC.CommandSingleplexer", "results == %O\n", results))

    	    fun(@results, args);
	    return;
	}
    }
    
    P0(("PSYC.CommandSingleplexer", "Cannot find a handler for command '%s'.\n", command))
}
