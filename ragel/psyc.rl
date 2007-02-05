// vim:syntax=ragel
#include <stdio.h>
#ifdef __PIKE__
# include "global.h"
# include "interpret.h"
# include "stralloc.h"
# include "mapping.h"
# include "svalue.h"
# include "array.h"
# include "module.h"
#else
# include <string.h>
# include <stdlib.h>
#endif

struct state {
    int cs, top;
};

struct depth {
    struct depth *up;
    struct depth *key;
#ifdef __PIKE__
    struct svalue *var;
#endif
    int level;
    int state;
};

%%{
    machine psyc;
    write data noerror nofinal;

    action descend {
	last = cur;
	cur->state = ftargs;
#ifndef __PIKE__
	printf("descending before state %d at '%c' (pos: %d).\n", ftargs, fc, (int)fpc);
#endif
	// TODO: use pikes alloc
	cur = (struct depth*)malloc(sizeof(struct depth));

	if (cur == NULL) {
#ifdef __PIKE__
	    Pike_error("malloc failed.");
#else
	    printf("malloc returned NULLLLLL!!!1!\n");
	    exit(-1);
#endif
	}

	memset(cur, 0, sizeof(struct depth));
	cur->level = last->level+1;
	cur->up = last;
    }

    action free {
	//free(last);
    }

    action ascend {
	last = cur;
#ifdef __PIKE__
	if (last->var->type == PIKE_T_MAPPING) {
	    //free(last->key);
	}
#endif
	cur = cur->up;

	if (cur == NULL) {
#ifdef __PIKE__
	    Pike_error("pointer gone to heaven at! length: %d\t cur: %d\t last: %d\t at '%.*s'\n", data->len, cur->state, last->state, MINIMUM(10, (int)(pe - p)), p);
#else
	    printf("pointer gone to heaven!\n");
	    exit(-1);
#endif
	}

#ifndef __PIKE__
	printf("ascending to %d at '%c' (pos: %d).\n", cur->state, fc, (int)fpc);
#endif
    }

    action jump {
	fgoto *cur->state;
    }

    action begin_string {
#ifdef __PIKE__
	reset_string_builder(&s);
#else
	printf("beginning string.\n");
#endif
    }

    action mark { i = fpc; }
    action marknext { i = fpc + 1; }

    action string_append {
#ifdef __PIKE__
	if (fpc - i > 0) {
	    string_builder_binary_strcat(&s, i, (ptrdiff_t)(fpc - i));
	}
#endif
    }

    action string_unquote {
#ifdef __PIKE__
	switch (fc) {
	case 'n':	string_builder_putchar(&s, '\n'); break;
	case 't':	string_builder_putchar(&s, '\t'); break;
	case 'r':	string_builder_putchar(&s, '\r'); break;
	case 'f':	string_builder_putchar(&s, '\f'); break;
	case 'b':	string_builder_putchar(&s, '\b'); break;
	case '"':
	case '\\':	string_builder_putchar(&s, fc); break;
	}
#endif
    }

    action end_string {
#ifdef __PIKE__
	cur->var = (struct svalue*)malloc(sizeof(struct svalue));
	cur->var->type = PIKE_T_STRING;
	cur->var->u.string = finish_string_builder(&s);
#else
	printf("string: '%.*s' length: %d\n", (int)(fpc - i), i, fpc - i);
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
    ) >mark >begin_string @end_string @ascend @jump;

    action begin_mapping {
#ifdef __PIKE__
	cur->var = (struct svalue*)malloc(sizeof(struct svalue));
	cur->var->type = PIKE_T_MAPPING;
	cur->var->u.mapping = debug_allocate_mapping(8);
#else
	printf("beginning mapping.\n");
#endif
    }

    action end_mapping {
#ifndef __PIKE__
	printf("end mapping.\n");
#endif
    }

    action add_mapping {
#ifdef __PIKE__
	mapping_insert(cur->var->u.mapping, cur->key->var, last->var);
#endif
    }

    alphtype char;
    access fsm.;

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
		    '"' >descend >{ fgoto string; } . myspace* . ':' >{ cur->key = last; } >descend >{ fgoto value; } -> more |
		    '}' -> final
		  ),
		  more: myspace* . (
		    ',' -> start|
		    '}' -> final
		  ) >add_mapping
    ) >begin_mapping @ascend @jump;

    action begin_array {
#ifdef __PIKE__	
	cur->var = (struct svalue*)malloc(sizeof(struct svalue));
	cur->var->type = PIKE_T_ARRAY;
	cur->var->u.array = low_allocate_array(0, 8);
#endif
    }

    action add_array {
#ifdef __PIKE__	
	
	cur->var->u.array = append_array(cur->var->u.array, last->var);
#endif
//	free(last);
    }

    array := ( myspace* . (any - myspace) >descend >{ fhold; fgoto value;} . myspace* . (','  |  ']' @ascend @jump ) >add_array )*;

    value = (myspace* . (
		  '"' >{ fgoto string; } |
		  '{' >{ fgoto mapping; } |
		  '[' >begin_array >{ fgoto array; }
		 ) . myspace* );

    method = '_' . (alnum | '_')+;
    variable_name = [:=+-?] . method;
    var = variable_name >descend >mark >begin_string
	    . '\t' >string_append >end_string @ascend @{ cur->key = last; }
	    . value >descend . '\n' >add_mapping;

    action store_vars {
	// a check to find out if any vars were found.
	if (cur->var->type == PIKE_T_MAPPING) {
	    c = find_identifier("vars", prog);
	    object_low_set_index(o, c, cur->var);
	}
    }

    main := var* . method >store_vars >mark >begin_string . '\n' >string_append >end_string @{ done = 1; };
}%%

#ifdef __PIKE__
/*! @module Public
 */

/*! @module Parser
 */

/*! @module PSYC
 */

/*! @decl mapping parse(string s)
 *!
 *! Parses a JSON-formatted string and returns the corresponding mapping.
 */
PIKEFUN int parse(string data, object o) {
    char *p, *pe, *i;
    int c;
    char done = 0;
    struct depth *cur, *last;
    // we wont be building more than one string at once.
    struct string_builder s;
    struct state fsm;
    struct program *prog;

    if (!o || !(prog=o->prog)) {
	Pike_error("Lookup in destructed object.\n");
    }

    if (data->size_shift != 0) {
	Pike_error("Size shift != 0.");
	// no need to return. does a longjmp
    }

    // length n can be alot but is certainly enough.
    init_string_builder(&s, 1);

    p = (char*)STR0(data);
    pe = p + data->len;

    cur = (struct depth*)malloc(sizeof(struct depth));
    memset(cur, 0, sizeof(struct depth));
    cur->level = 0;

    cur->var = (struct svalue*)malloc(sizeof(struct svalue));
    cur->var->type = PIKE_T_MAPPING;
    cur->var->u.mapping = debug_allocate_mapping(8);

    %%
    %% write init;
    %% write exec;


    if ( done != 1 ) {
	//if (cur) free(cur);
	Pike_error("length: %d\t cur: %d\t last: %d\t at '%.*s'\n", data->len, cur->state, last->state, MINIMUM(10, (int)(pe - p)), p);
	//free_string_builder(&s);
    }

    c = find_identifier("mc", prog);
    object_low_set_index(o, c, cur->var);

    if (pe - p > 0) {
	reset_string_builder(&s);
	string_builder_binary_strcat(&s, p, (ptrdiff_t)(pe - p));
	cur->var->u.string = finish_string_builder(&s);
    } else {
	cur->var->u.string = empty_pike_string;
    }

    c = find_identifier("data", prog);
    object_low_set_index(o, c, cur->var);

    // extract the mc.
    //free(cur);
    //free_string_builder(&s);

    RETURN (INT_TYPE)0;
}

#else

int parse_psyc(char *d, struct state *f, int n) {
    char *p = d;
    char *pe = d + n;
    char *i = p;
    char done = 0;
    struct state fsm = *f;

    struct depth *cur, *last, *key;
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

    return 0;
}

int main() {
    struct state fsm;

    char *one = "_sdlkf	\"hihihi\\\"\"\n_hallo	{ \"sdf\"  : \"sdf\", \"hihihahahiahia\\n\\f\" : \"\"}\n_hehe\t[ \"juchuu\" , \"wulle wulle wu\"   ]\n_message_public\nlksadsalkf ashdf kjhsafkj hsdakhf s\n\n\n\n";
    printf("%s\n", one);
    parse_psyc(one, &fsm, strlen(one));

    return 0;
}
#endif

