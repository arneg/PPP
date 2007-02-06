// vim:syntax=ragel
#include <stdio.h>
%%{
    machine JSON_number;
    write data;

    # we could be much less specific here.. but i guess its ok to ensure the format not
    # correctness in the sense of sscanf 
    main := '-'? . ( '0' | ([1-9] . digit*) )? . '.' >{ d = 1; } . digit+ . ([eE] . [+\-] . digit+ )? %~{ fbreak; };
}%%

char *_parse_JSON_number(char *p, char *pe, 
#ifndef USE_PIKE_STACK
			 struct svalue *var, 
#endif
			 struct string_builder *s) {
    char *i = p;
    int cs;
    int d = 0;
#ifdef USE_PIKE_STACK
    double f;
#endif

    %% write init;
    %% write exec;

    if (cs >= JSON_number_first_final) {
	if (d == 1) {
#ifndef USE_PIKE_STACK
	    var->type = PIKE_T_FLOAT;
#endif
	    if (1 != sscanf(i, "%lf", 
#ifndef USE_PIKE_STACK
			    &(var->u.float_number)
#else
			    &f
#endif
			    )) return NULL;
#ifdef USE_PIKE_STACK
	    push_float(f);
#endif
	} else {
#ifndef USE_PIKE_STACK
	    var->type = PIKE_T_INT;
#endif
	    if (1 != sscanf(i, "%d", 
#ifndef USE_PIKE_STACK
			    &(var->u.integer)
#else
			    &d
#endif
			    )) return NULL;
	    push_int(d);
	}
	return p + 1;
    }

    return NULL;
}

