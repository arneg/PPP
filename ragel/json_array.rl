// vim:syntax=ragel
%%{
    machine JSON_array;
    write data;

    action parse_value {
#ifndef USE_PIKE_STACK
	value = (struct svalue*)malloc(sizeof(struct svalue));

	if (value == NULL) {
	    i = NULL;
	    fbreak;
	}

	memset(value, 0, sizeof(struct svalue));
#endif
	i = _parse_JSON(fpc, pe, 
#ifndef USE_PIKE_STACK
			value, 
#endif
			s);

#ifndef USE_PIKE_STACK
	if (i == NULL) {
	    free(value);
	    fbreak;
	}

	var->u.array = append_array(var->u.array, value);
#else
	c++;
#endif
	fexec i;
    }

    myspace = ' ';
    value_start = ["[{\-+.tf] | digit;

    main := '[' . myspace* . (
			      start: (
				']' -> final |
				value_start >parse_value . myspace* -> more
			      ),
			      more: (
				']' -> final |
				',' . myspace* -> start 
			      )
			     ) %*{ fbreak; };
}%%

char *_parse_JSON_array(char *p, char *pe, 
#ifndef USE_PIKE_STACK
			struct svalue *var, 
#endif
			struct string_builder *s) {
    char *i = p;
    int cs;
#ifndef USE_PIKE_STACK
    struct svalue *value; 

    var->type = PIKE_T_ARRAY;
    var->u.array = low_allocate_array(0, 8);
#else
    int c = 0;
#endif

    %% write init;
    %% write exec;

    if (
#ifndef USE_PIKE_STACK
	i != NULL && 
#endif
	cs >= JSON_array_first_final) {
#ifdef USE_PIKE_STACK
	f_aggregate(c);
#endif
	return p;
    }
    // error
#ifndef USE_PIKE_STACK
    do_free_array(var->u.array);
#else
    pop_n_elems(c);
    Pike_error("Error parsin array at '%.*s'\n", MINIMUM((int)(pe - p), 10), p);
#endif
    return NULL;
}

