// vim:syntax=ragel
%%{
    machine JSON_mapping;
    alphtype int;
    write data;

    action parse_value {
	i = _parse_JSON(fpc, pe, validate);

	if (i == NULL) {
	    if (!validate &&c > 0) stack_pop_n_elems_keep_top(c);
	    return NULL;
	}

	c++;

	fexec i;
    }

    action parse_key {
	i = _parse_JSON_string(fpc, pe, validate);

	if (i == NULL) {
	    if (!validate && c > 0) stack_pop_n_elems_keep_top(c);
	    return NULL;
	}

	c++;

	fexec i;
    }

    myspace = [ \n\r\t];
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

p_wchar2 *_parse_JSON_mapping(p_wchar2 *p, p_wchar2 *pe, short validate) {
    p_wchar2 *i = p;
    int cs;
    int c = 0;

    %% write init;
    %% write exec;

    if (cs >= JSON_mapping_first_final) {
	if (!validate) f_aggregate_mapping(c);
	return p;
    }

    if (!validate) {
	if (c > 0) pop_n_elems(c);
#ifdef JUMP
	Pike_error("Error parsing mapping at '%c'.\n", (char)*p);
#endif
    }

    push_int((int)p);
    return NULL;
}

