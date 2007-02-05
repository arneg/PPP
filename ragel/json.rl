// vim:syntax=ragel
#include <stdio.h>
#ifdef __PIKE__
# include "global.h"
# include "interpret.h"
# include "stralloc.h"
# include "mapping.h"
# include "svalue.h"
# include "array.h"
# include "module.h"
#else
# include <string.h>
# include <stdlib.h>
#endif

struct state {
    int cs, top;
};

%%{
    machine JSON;
    write data noerror nofinal;

    value_start = ["[{\-+.tf] | digit;

    myspace = ' ';

    main := myspace*;
}%%

char *_parse_JSON(char *p, char *pe, struct svalue *var) {
    struct state fsm;

    init_string_builder(&s, 1);

    %% write init;
    %% write exec;

    struct string_builder s;
}

#ifdef __PIKE__
/*! @module Public
 */

/*! @module Parser
 */

/*! @module PSYC
 */

/*! @decl mapping parse(string s)
 *!
 *! Parses a JSON-formatted string and returns the corresponding mapping.
 */
PIKEFUN mixed parse_JSON(string data) {
    // we wont be building more than one string at once.

    if (!o || !(prog=o->prog)) {
	Pike_error("Lookup in destructed object.\n");
    }

    if (data->size_shift != 0) {
	Pike_error("Size shift != 0.");
	// no need to return. does a longjmp
    }

    // length n can be alot but is certainly enough.



    RETURN (INT_TYPE)0;
}
#endif

