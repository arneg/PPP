// vim:syntax=ragel
%%{
    machine JSON_mapping;
    write data;

    action parse_value {
#ifndef USE_PIKE_STACK
	value = (struct svalue*)malloc(sizeof(struct svalue));

	if (value == NULL) {
	    free(key);
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
# ifdef DEBUG
	printf("value: %p. null: %p\n", i, NULL);
# endif

#ifdef USE_PIKE_STACK
	c++;
#else
	if (i == NULL) {
	    free(key);
	    free(value);
	    fbreak;
	}
# ifdef DEBUG
	printf("adding key:\n");
	print_svalue(stdout, key);
	printf("and value:\n");
	print_svalue(stdout, value);
	printf("\n");
# endif
	mapping_insert(var->u.mapping, key, value);
#endif
	fexec i;
    }

    action parse_key {
#ifndef USE_PIKE_STACK
	key = (struct svalue*)malloc(sizeof(struct svalue));

	if (key == NULL) {
	    i = NULL;
	    fbreak;
	}

	memset(key, 0, sizeof(struct svalue));
#endif
	i = _parse_JSON_string(fpc, pe, 
#ifndef USE_PIKE_STACK
			       key, 
#endif
			       s);
#ifdef USE_PIKE_STACK
	c++;
#else
	if (i == NULL) {
	    free(key);
	    fbreak;
	}
#endif
	fexec i;
    }

    myspace = ' ';
    value_start = ["[{\-+.tf] | digit;

    main := '{' . myspace* . (
			start: (
			    '}' -> final |
			    '"' >parse_key . myspace* . ':' -> value
			),
			value: (
			    myspace* . value_start >parse_value . myspace* -> repeat
		        ),
			repeat: (
			    ',' . myspace* -> start |
			    '}' -> final
			)
		       ) %*{ fbreak; };
}%%

char *_parse_JSON_mapping(char *p, char *pe, 
#ifndef USE_PIKE_STACK
			  struct svalue *var, 
#endif
			  struct string_builder *s) {
    char *i = p;
    int cs;
#ifndef USE_PIKE_STACK
    struct svalue *key, *value; 

    var->type = PIKE_T_MAPPING;
    var->u.mapping = debug_allocate_mapping(8);
#else
    int c = 0;
#endif

#ifdef DEBUG
    printf(">> MAPPING \n");
#endif

    %% write init;
    %% write exec;
#ifdef DEBUG
    printf("stopping parsing of mapping at '%.*s ...' in state %d\n", MINIMUM(pe - p, 10), p, cs);
    printf("<< MAPPING \n");
#endif


    if (
#ifndef USE_PIKE_STACK
	i != NULL && 
#endif
	cs >= JSON_mapping_first_final) {
#ifdef USE_PIKE_STACK
	f_aggregate_mapping(c);
#endif
	return p;
    }
#ifdef USE_PIKE_STACK
    pop_n_elems(c);

    Pike_error("Error parsing mapping at '%.*s'.\n", MINIMUM(pe - p, 10), p);
#else
    do_free_mapping(var->u.mapping);
#endif
    // error
    return NULL;
}

