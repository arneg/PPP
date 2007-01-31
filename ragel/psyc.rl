// vim:syntax=ragel
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#ifdef PIKE
# include <stralloc.h>
# include <mapping.h>
# include <svalue.h>
#endif

struct state {
    int cs, top, stack[32]; 
};

struct depth {
    struct depth *up;
#ifdef PIKE
    TYPE_T type;
    void *var;
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
	tmp = cur;
	cur->state = ftargs;
	printf("descending before state %d at '%c' (pos: %d).\n", ftargs, fc, (int)fpc);
	// TODO: use pikes alloc
	cur = (struct depth*)malloc(sizeof(struct depth));

	if (cur == NULL) {
	    // TODO: Pike error
	    printf("malloc returned NULLLLLL!!!1!\n");
	    exit(-1);
	}
	cur->level = tmp->level+1;
	cur->up = tmp;
    }

    action ascend {
	tmp = cur;
	cur = cur->up;

	if (cur == NULL) {

	    printf("pointer gone to heaven!\n");
	    exit(-1);
	}

	free(tmp);
	printf("ascending to %d at '%c' (pos: %d).\n", cur->state, fc, (int)fpc);
	fgoto *cur->state;
    }

    action begin_string {
	printf("beginning string.\n");
	i = fpc;
#ifdef PIKE
	cur->var = malloc(sizeof(struct pike_string));
	cur->type = PIKE_T_STRING;
#endif
    }

    action end_string {
	printf("string: '%.*s' length: %d\n", (int)(fpc - i), i, fpc - i);
    }

    string := (
	       start: (
		    '"' -> final |
		    '\\' -> unquote |
		    (any - ["\\]) -> start
		),
		unquote: (
		    [nt"\\/bfnrt] -> start
		) 
    ) >begin_string @end_string @ascend;

    action begin_mapping {
	printf("beginning mapping.\n");
    }

    action end_mapping {
	printf("end mapping.\n");
    }
    alphtype char;
    access fsm->;

    myspace = ' ';

    mapping := (
		  start: myspace* . (
		    '"' >descend >{ fgoto string; } . myspace* . ':' >descend >{ printf("value:\n"); fgoto value; } -> more |
		    '}' -> final
		  ),
		  more: myspace* . (
		    ',' -> start|
		    '}' -> final
		  )
    ) @ascend;

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
    variable = (variable_name . '\t' . value >descend . '\n' )+ . variable_name . '\n' @{ done = 1; };

    main := variable;
}%%

#if 0
PIKECLASS Util {

    PSYCFUN int parse_psyc(string data, object o) {

    }
}
#endif

int parse_uniform(const char *d, struct state *fsm, int n) {
    const char *p = d;
    const char *pe = d + n;
    const char *i = 0;
    char done = 0;

    struct depth *cur, *tmp;
    cur = (struct depth*)malloc(sizeof(struct depth));
    cur->level = 0;

    %% write init;
    %% write exec;

    printf("the machine stopped at char %c at position %d in state %d. left: %d, length: %d\n", *p, (int)p, fsm->cs, (int)(pe - p), strlen(p));
    if ( done == 1 ) {
	printf("The machine parsed the packet successfully. data is: '%.*s'\n", pe - p, p);
    } else {
	printf("Error while parsing.");
    }

    return 0;
}


int main() {
    struct state fsm;

    const char *one = "_sdlkf	\"hihihi\\\"\"\n_hallo	{ \"sdf\"  : \"sdf\", \"hihihahahiahia\\n\\f\" : \"\"}\n_hehe\t[ \"juchuu\" , \"wulle wulle wu\"   ]\n_message_public\nlksadsalkf ashdf kjhsafkj hsdakhf s\n\n\n\n";
    printf("%s\n", one);
    parse_uniform(one, &fsm, strlen(one));

    return 0;
}

