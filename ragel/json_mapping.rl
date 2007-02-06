// vim:syntax=ragel
%%{
    machine JSON_mapping;
    write data nofinal;

    action parse_value {
	value = (struct svalue*)malloc(sizeof(struct svalue));
	memset(value, 0, sizeof(struct svalue));
	i = _parse_JSON(fpc, pe, value, s);

	if (i == NULL) {
	    free(key);
	    free(value);
	    fbreak;
	}

	mapping_insert(var->u.mapping, key, value);
	fexec i;
    }

    action parse_key {
	key = (struct svalue*)malloc(sizeof(struct svalue));
	memset(key, 0, sizeof(struct svalue));
	i = _parse_JSON_string(fpc, pe, key, s);

	if (i == NULL) {
	    free(key);
	    fbreak;
	}

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
		       );
}%%

char *_parse_JSON_mapping(char *p, char *pe, struct svalue *var, struct string_builder *s) {
    char *i = p;
    int cs;
    struct svalue *key, *value; 

    var->type = PIKE_T_MAPPING;
    var->u.mapping = debug_allocate_mapping(8);

    %% write init;
    %% write exec;

    // error
    if (cs == JSON_mapping_error || i == NULL) {
	do_free_mapping(var->u.mapping);
	return NULL;
    }
}

