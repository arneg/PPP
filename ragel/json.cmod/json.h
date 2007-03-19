#define PUSH_SPECIAL(X) if (!validate) do { 					\	
	    struct program *prog; 						\
	    push_text("Public.Parser.JSON2." X); 				\
	    SAFE_APPLY_MASTER("resolv", 1); 					\
	    if (((struct svalue *)(Pike_sp - 1))->type != PIKE_T_PROGRAM) { 	\
		Pike_error("Could not resolv object %s.\n", X); 		\
	    } 									\
	    prog = (struct svalue *)(Pike_sp - 1))->u.program; 			\
	    pop_stack(); 							\
	    push_object(debug_clone_object(prog, 3));				\
	} while(0)

#define PARSE(X) i = _parse_JSON_##X(fpc, pe, validate);			\
	if (validate && i == NULL) {						\
	    return NULL;							\
	}									\

#define JSON_CONVERT(a,b) switch (a->size_shift != 0) {				\
    case 0:									\
	b=begin_wide_shared_string(a->len,2);					\
        convert_0_to_2(STR2(b),(p_wchar0 *)a->str,a->len);			\
	free_string(a);								\
	end_shared_string(b);							\
	break;									\
    case 1:									\
	b=begin_wide_shared_string(a->len,2);					\
        convert_1_to_2(STR2(b),STR1(a),a->len);					\
	free_string(a);								\
	end_shared_string(b);							\
	break;									\
    case 2:									\
	b = data;								\
	break;									\
    }
