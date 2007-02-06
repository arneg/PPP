// vim:syntax=ragel
#include <stdio.h>
%%{
    machine JSON_number;

    # we could be much less specific here.. but i guess its ok to ensure the format not
    # correctness in the sense of sscanf 
    main := '-'? . ( '0' | ([1-9] . digit*) )? . '.' >{ d = 1; } . digit+ . ([eE] . [+\-] . digit+ )?;
}%%

char *_parse_JSON_array(char *p, char *pe, struct svalue *var, struct string_builder *s) {
    char *i = p;
    int cs;
    int d = 0;

    %% write init;
    %% write exec;

    if (cs == JSON_number_error) {
	return NULL;
    }

    if (d == 1) {
	s->type = PIKE_T_FLOAT;
	if (1 != sscanf(i, "%lf", &(s->u.float_number))) return NULL;
    } else {
	s->type = PIKE_T_INTEGER;
	if (1 != sscanf(i, "%d", &(s->u.integer))) return NULL;
    }

    return p;
}

