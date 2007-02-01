// vim:syntax=ragel
#include <stdio.h>
#ifdef PIKE
# include "global.h"
# include "stralloc.h"
# include "mapping.h"
# include "svalue.h"
# include "dmalloc.h"
# include "module.h"
#else
# include <stdlib.h>
#endif

struct state {
    int cs, top; 
};

struct depth {
    struct depth *up;
#ifdef PIKE
    struct svalue var;
#endif
    int level;
    int state;
};


%%{
    machine psyc;
    write data noerror nofinal;

    action begin {
	i = fpc;
    }

    action end {
	printf("stopping at %d\n", (int)fpc);
	printf("host: '%.*s' length: %d\n", (int)(fpc - i), i, fpc - i);
    }

    action descend {
	last = cur;
	cur->state = ftargs;
	printf("descending before state %d at '%c' (pos: %d).\n", ftargs, fc, (int)fpc);
	// TODO: use pikes alloc
	cur = (struct depth*)malloc(sizeof(struct depth));

	if (cur == NULL) {
	    // TODO: Pike error
	    printf("malloc returned NULLLLLL!!!1!\n");
	    exit(-1);
	}
	cur->level = last->level+1;
	cur->up = last;
    }

    action free {
	free(last);
    }

    action ascend {
	last = cur;
	cur = cur->up;

	if (cur == NULL) {

	    printf("pointer gone to heaven!\n");
	    exit(-1);
	}

	// keep the key, for gods sake!
	printf("ascending to %d at '%c' (pos: %d).\n", cur->state, fc, (int)fpc);
	fgoto *cur->state;
    }

    action begin_string {
	printf("beginning string.\n");
#ifdef PIKE
	reset_string_builder(&s);
#endif
    }

    action mark { i = fpc; }
    action marknext { i = fpc + 1; }

    action string_append {
	if (fpc - i - 1 > 0) {
	    string_builder_binary_strcat(&s, i, (ptrdiff_t)(fpc - i - 1)); 
	}
    }

    action string_unquote {
	switch (fc) {
	case 'n':	string_builder_putchar(&s, '\n'); break;
	case 't':	string_builder_putchar(&s, '\t'); break;
	case 'r':	string_builder_putchar(&s, '\r'); break;
	case 'f':	string_builder_putchar(&s, '\f'); break;
	case 'b':	string_builder_putchar(&s, '\b'); break;
	case '"':
	case '\\':	string_builder_putchar(&s, fc); break;
	}
    }

    action end_string {
	printf("string: '%.*s' length: %d\n", (int)(fpc - i), i, fpc - i);
#ifdef PIKE
	cur->var.type = PIKE_T_STRING;
	cur->var.u.string = finish_string_builder(&s);
#endif
    }

#	PIKE API:
#
#	string_builder_binary_strcat(string_builder *s, char *str, int lenth)
#
#	struct pike_string *finish_string_builder(struct string_builder *s)
#
#	void string_builder_append(struct string_builder *s,                                                                      
#	                           PCHARP from,                                           
#	                           ptrdiff_t len)
#
#	void string_builder_putchar(struct string_builder *s, int ch)
    string := (
	       start: (
		    '"' >string_append -> final |
		    '\\' >string_append -> unquote |
		    (any - ["\\]) -> start
		),
		unquote: (
		    [nt"\\/bfnrt] >string_unquote @marknext -> start
		) 
    ) >mark >begin_string @end_string @ascend;

    action begin_mapping {
	printf("beginning mapping.\n");
#ifdef PIKE
	cur->var.type = PIKE_T_MAPPING;
	cur->var.u.mapping = debug_allocate_mapping(8);
#endif
    }

    action end_mapping {
	printf("end mapping.\n");
    }

    action add_mapping {
#ifdef PIKE
	mapping_insert(cur->var.u.mapping, &key->var, &last->var); 
#endif
	free(key);
	free(last);
    }

    alphtype char;
    access fsm->;

    myspace = ' ';

#	PIKE API
#
#	struct mapping *debug_allocate_mapping(int size)
#
#	mapping_insert(struct mapping *m,
#                        struct svalue *key,
#                       struct svalue *val)
    mapping := (
		  start: myspace* . (
		    '"' >descend >{ fgoto string; } . myspace* . ':' >{ key = last; } >descend >{ printf("value:\n"); fgoto value; } -> more |
		    '}' -> final
		  ),
		  more: myspace* . (
		    ',' -> start|
		    '}' -> final
		  ) >add_mapping
    ) >begin_mapping @ascend;

    action begin_number {
	printf("beginning number\n");
    }

    array := ( myspace* . (any - myspace) >descend >{ fhold; fgoto value;} . myspace* . (',' |  ']' >ascend ) )*;

    
    #json
    value = (myspace* . (
		  '"' >{ fgoto string; } |
		  '{' >{ fgoto mapping; } |
		  '[' >{ fgoto array; }
		 ) . myspace* );

    variable_name = '_' . (alpha | '_')+;
    variable = variable_name . '\t' . value >descend . '\n';

    main := variable* . variable_name . '\n' @{ done = 1; };
}%%

#if 0
PIKECLASS Util {

    PSYCFUN int parse_psyc(string data, object o) {

    }
}
#endif

int parse_psyc(char *d, struct state *fsm, int n) {
    char *p = d;
    char *pe = d + n;
    char *i = p;
    char done = 0;

    struct depth *cur, *last, *key;
#ifdef PIKE
    // we wont be building more than one string at once.
    struct string_builder s;
    // length n can be alot but is certainly enough.
    string_builder_allocate(&s, n, 0);
#endif
    cur = (struct depth*)malloc(sizeof(struct depth));
    cur->level = 0;

    %% write init;
    %% write exec;

    printf("the machine stopped at char %c at position %d in state %d. left: %d, length: %d\n", *p, (int)p, fsm->cs, (int)(pe - p), strlen(p));
    free(cur);
    if ( done == 1 ) {
	printf("The machine parsed the packet successfully. data is: '%.*s'\n", pe - p, p);
    } else {
	printf("Error while parsing.");
    }

#ifdef PIKE
    free_string_builder(&s);
#endif

    return 0;
}


int main() {
    struct state fsm;

    char *one = "_sdlkf	\"hihihi\\\"\"\n_hallo	{ \"sdf\"  : \"sdf\", \"hihihahahiahia\\n\\f\" : \"\"}\n_hehe\t[ \"juchuu\" , \"wulle wulle wu\"   ]\n_message_public\nlksadsalkf ashdf kjhsafkj hsdakhf s\n\n\n\n";
    printf("%s\n", one);
    parse_psyc(one, &fsm, strlen(one));

    return 0;
}

