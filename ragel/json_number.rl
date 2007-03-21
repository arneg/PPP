// vim:syntax=ragel
#include <stdio.h>
%%{
    machine JSON_number;
    alphtype int;
    write data;
    # we could be much less specific here.. but i guess its ok to ensure the 
    # format not correctness in the sense of sscanf 
    # 
    action break {
	fbreak;
    }

    end = [\]},: ];
    exp = [eE] >{d = 1;}. [+\-]? . digit+ . (end >break)?;
    float = '.' >{d = 1;} . digit+ . (end >break | exp)?;
    main := '-' ? . (('0' | ([1-9] . digit*)) . (end >break | float | exp)?) | float; 
}%%

p_wchar2 *_parse_JSON_number(p_wchar2 *p, p_wchar2 *pe, short validate) {
    p_wchar2 *i = p;
    int cs;
    int d = 0;
    double f;

    %% write init;
    %% write exec;

    if (cs >= JSON_number_first_final) {
	
	if (!validate) {
	    ptrdiff_t len = (ptrdiff_t)(p - i); 

	    char *temp = (char*)malloc(len+1);

	    if (temp == NULL) {
		Pike_error("Not enough memory while parsing a number from JSON!");
	    }

	    *(temp + len--) = '\0';
	    
	    do {
		*(temp + len) = (char)(*(i + len));
	    } while(len-- > 0);

	    len = (ptrdiff_t)(p - i);

	    if (d == 1) {
		if (1 != sscanf(temp, "%lf", &f)) {
		    Pike_error("Error parsing float (%.*s) in JSON.", MINIMUM(len, 10), temp);
		}
		push_float(f);
	    } else {
		if (1 != sscanf(temp, "%d", &d)) {
		    Pike_error("Error parsing integer (%.*s) in JSON.", MINIMUM(len, 10), temp);
		}
		push_int(d);
	    }
	}

	return p;
    }

#ifdef JUMP
    if (!validate) Pike_error("Error parsing number at '%c' in JSON.\n", (char)*i);
#endif

    push_int((int)p);
    return NULL; // make gcc happy
}

