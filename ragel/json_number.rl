// vim:syntax=ragel
#include <stdio.h>
%%{
    machine JSON_number;
    write data;

    # we could be much less specific here.. but i guess its ok to ensure the format not
    # correctness in the sense of sscanf 
    main := '-'? . ( '0' | ([1-9] . digit*) )? . '.' >{ d = 1; } . digit+ . ([eE] . [+\-] . digit+ )?;
}%%

char *_parse_JSON_number(char *p, char *pe, struct svalue *var, struct string_builder *s) {
    char *i = p;
    int cs;
    int d = 0;

    %% write init;
    %% write exec;

    if (cs >= JSON_number_first_final) {
	if (d == 1) {
	    var->type = PIKE_T_FLOAT;
	    if (1 != sscanf(i, "%lf", &(var->u.float_number))) return NULL;
	} else {
	    var->type = PIKE_T_INT;
	    if (1 != sscanf(i, "%d", &(var->u.integer))) return NULL;
	}
	return p + 1;
    }

    return NULL;
}

