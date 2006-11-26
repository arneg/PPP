// vim:syntax=lpc
#include <debug.h>

mapping commands = ([]);

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

void cmd(string input) {
    PT(("PSYC.CommandSingleplexer", "cmd(%O)\n", input))
	
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
		PT(("PSYC.CommandSingleplexer", "break!!>!\n"))
		break;
	    }

	    foreach (specs/2;; array spec) {
		int type, stat;
		string name;
		mixed result;

		[type, name] = spec;

		if (sizeof(params) <= i) {
		    PT(("PSYC.CommandSingleplexer", "sizeof(params)(==%O) <= %O\n", sizeof(params), i))
		    break COMMAND;
		}
		
		[stat, result] = PSYC.Commands.parse(type, params[i..], this);

		if (stat == 0) {
		    PT(("PSYC.CommandSingleplexer", "a parse(%O) failed, hooray.\n", type))
		    break COMMAND;
		}

		i += stat;
		results += ({ result });
	    }

	    PT(("PSYC.CommandSingleplexer", "results == %O\n", results))

    	    fun(@results, params);
	    return;
	}
    }
    
    PT(("PSYC.CommandSingleplexer", "could not find a handler for the input.\n"))
}
