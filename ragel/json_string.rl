// vim:syntax=ragel
#define HEX2DEC(x) ((x) <= '9' ? (x) - '0' : ((x) < 'G') ? (x) - 'A' + 10 : (x) - 'a' + 10)

%%{
    machine JSON_string;
    write data nofinal;

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
		  ) >mark;
}%%

char *_parse_JSON_string(char *p, char *pe, struct svalue *var, struct string_builder *s) {
    char temp = 0;
    char *mark = 0;
    int cs;

    init_string_builder(s, 1);

    %% write init;
    %% write exec;

    if (cs == JSON_string_error ) {
	return NULL;
    }

    var->type = PIKE_T_STRING;
    var->u.string = finish_string_builder(s);

    return p;
}
