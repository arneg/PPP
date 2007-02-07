// vim:syntax=ragel
#define HEX2DEC(x) ((x) <= '9' ? (x) - '0' : ((x) < 'G') ? (x) - 'A' + 10 : (x) - 'a' + 10)

%%{
    machine JSON_string;
    write data;

    action hex1 {
	temp += HEX2DEC(fc) * 16;
    }

    action hex2 {
	string_builder_putchar(s, temp + HEX2DEC(fc));
	temp = 0;
    }

    action add_unquote {
	switch(fc) {
        case '"':
        case '\\':      string_builder_putchar(s, fc); break;
        case 'b':       string_builder_putchar(s, '\b'); break;
        case 'f':       string_builder_putchar(s, '\f'); break;
	case 'n':       string_builder_putchar(s, '\n'); break;
        case 'r':       string_builder_putchar(s, '\r'); break;
        case 't':       string_builder_putchar(s, '\t'); break;
	}
    }

    action mark {
	mark = fpc;
    }

    action mark_next { mark = fpc + 1; }

    action string_append {
	if (fpc - mark > 0) {
            string_builder_binary_strcat(s, mark, (ptrdiff_t)(fpc - mark));
#ifdef DEBUG
	    printf("parsed string: '%.*s'\n", (int)(fpc - mark), mark);
#endif
        }
    }

    main := '"' . (
		   start: (
		       '"' >string_append -> final |
		       '\\' >string_append -> unquote |
		       (any - [\\"]) -> start
		   ),
		   unquote: (
		       ["\\/bfnrt] >add_unquote -> start |
		       'u' . (xdigit >hex1 . xdigit >hex2){2} -> start
		   ) @mark_next
		  ) >mark %*{ fbreak; };
}%%

char *_parse_JSON_string(char *p, char *pe, 
#ifndef USE_PIKE_STACK
			 struct svalue *var, 
#endif
			 struct string_builder *s) {
    char temp = 0;
    char *mark = 0;
    int cs;
    init_string_builder(s, 1);

#ifdef DEBUG
    printf(">> STRING\nstarting to parse string at %.*s \n", MINIMUM(pe - p, 10), p);
#endif

    %% write init;
    %% write exec;

    if (cs < JSON_string_first_final) {
#ifdef DEBUG
	printf("failed parsing string at %.*s in state %d.\n", MINIMUM(pe - p, 10),p, cs);
#endif

#ifndef USE_PIKE_STACK
	return NULL;
#else
	Pike_error("Failed to parse string '%.*s'.\n", MINIMUM(pe - p, 10), p);
#endif
    }

#ifndef USE_PIKE_STACK
    var->type = PIKE_T_STRING;
    var->u.string = finish_string_builder(s);
#else
    push_string(finish_string_builder(s));
#endif

#ifdef DEBUG
    printf("stopping parsing string at %c in state %d.\n<< STRING\n", *p, cs);
#endif
    return p;
}
