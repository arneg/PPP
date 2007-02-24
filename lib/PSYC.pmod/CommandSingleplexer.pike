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
	
    array(string) params = input / " ";
    string command = params[0];

    if (has_index(commands, command)) {
COMMAND: foreach (commands[command];;array pair) {
	    function fun;
	    array specs;
	    int i = 1;
	    mixed results = ({ });

	    [fun, specs] = pair;

	    if (sizeof(specs) / 2 >= sizeof(params)) {
		P1(("PSYC.CommandSingleplexer", "break!!>!\n"))
		break;
	    }

	    foreach (specs/2;; array spec) {
		int type, stat;
		string name;
		mixed result;

		[type, name] = spec;

		if (sizeof(params) <= i) {
		    P1(("PSYC.CommandSingleplexer", "sizeof(params)(==%O) <= %O\n", sizeof(params), i))
		    break COMMAND;
		}
		
		[stat, result] = PSYC.Commands.parse(type, params[i..], this);

		if (stat == 0) {
		    P1(("PSYC.CommandSingleplexer", "a parse(%O) failed, hooray.\n", type))
		    break COMMAND;
		}

		i += stat;
		results += ({ result });
	    }

	    P1(("PSYC.CommandSingleplexer", "results == %O\n", results))

    	    fun(@results, params);
	    return;
	}
    }
    
    P0(("PSYC.CommandSingleplexer", "could not find a handler for the input.\n"))
}
