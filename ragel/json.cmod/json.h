#define PUSH_SPECIAL(X) if (!validate) { 				\
    push_text("Public.Parser.JSON2." X); 				\
    APPLY_MASTER("resolv", 1);						\
    if (((struct svalue*)(Pike_sp - 1))->type != PIKE_T_OBJECT) { 	\
	Pike_error("Could not resolv program '%s'\n.", 			\
		   "Public.Parser.JSON2." X );  			\
    } 									\
}

#define PARSE(X, FPC) i = _parse_JSON_##X(FPC, pe, validate);		\
    if (i == NULL) {							\
	return NULL;							\
    }									\
    c++;								\

#define JSON_CONVERT(a,b) do {						\
    b=(p_wchar2 *)malloc(sizeof(int) * a->len);				\
    if (b == NULL) {							\
	Pike_error("Not enough memory while Parsing.\n");		\
    }									\
    switch (a->size_shift) {						\
    case 0:								\
        convert_0_to_2(b,STR0(a), a->len);				\
	break;								\
    case 1:								\
        convert_1_to_2(b,STR1(a), a->len);				\
	break;								\
    case 2:								\
	b = STR2(a);							\
	break;								\
    } } while (0)
