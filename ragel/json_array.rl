// vim:syntax=ragel
%%{
    machine JSON_array;
    alphtype int;
    write data;

    action parse_value {
	i = _parse_JSON(fpc, pe);

	c++;
	fexec i;
    }

    myspace = [ \n\r\t];
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

p_wchar2 *_parse_JSON_array(p_wchar2 *p, p_wchar2 *pe) {
    p_wchar2 *i = p;
    int cs;
    int c = 0;

    %% write init;
    %% write exec;

    if (cs >= JSON_array_first_final) {
	f_aggregate(c);
	return p;
    }
    // error
    pop_n_elems(c);
    Pike_error("Error parsin array at '%c'\n", (char)*p);
    return NULL;
}

