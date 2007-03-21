// vim:syntax=ragel
%%{
    machine JSON_array;
    alphtype int;
    write data;

    action parse_value {
	i = _parse_JSON(fpc, pe, validate);

	if (i == NULL) {
	    if (!validate && c > 0) stack_pop_n_elems_keep_top(c);
	    return NULL;
	}

	c++;
	fexec i;
    }

    myspace = [ \n\r\t];
    value_start = ["[{\-+.tfn] | digit;

    main := ('[' . myspace* . (
			      start: (
				']' -> final |
				value_start >parse_value . myspace* -> more
			      ),
			      more: (
				']' -> final |
				',' . myspace* -> start 
			      )
			     ) %*{ fbreak; }) ;
}%%

p_wchar2 *_parse_JSON_array(p_wchar2 *p, p_wchar2 *pe, short validate) {
    p_wchar2 *i = p;
    int cs;
    int c = 0;

    %% write init;
    %% write exec;

    if (cs >= JSON_array_first_final) {
	if (!validate) f_aggregate(c);
	return p;
    }

    if (!validate) {
	if (c > 0) pop_n_elems(c);
#ifdef JUMP
	Pike_error("Error parsing array at '%c'\n", (char)*p);
#endif
    }


    push_int((int)p);
    return NULL;
}
