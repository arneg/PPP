// vim:syntax=ragel
%%{
    machine JSON_mapping;
    alphtype int;
    write data;

    action parse_value {
	i = _parse_JSON(fpc, pe, validate);

	if (validate) {
	    if (i == NULL) return NULL;
	} else c++;

	fexec i;
    }

    action parse_key {
	i = _parse_JSON_string(fpc, pe, validate);

	if (validate) {
	    if (i == NULL) return NULL;
	} else c++;

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
	pop_n_elems(c);
	Pike_error("Error parsing mapping at '%c'.\n", (char)*p);
    }

    push_int((int)p);
    return NULL;
}

