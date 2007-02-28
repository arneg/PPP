// vim:syntax=ragel
#include <stdio.h>
#ifdef __PIKE__
# include "global.h"
# include "interpret.h"
# include "stralloc.h"
# include "mapping.h"
# include "svalue.h"
# include "array.h"
# include "builtin_functions.h"
# include "module.h"
#else
# include <string.h>
# include <stdlib.h>
#endif

#define push_n_text(T, n) do {						\
    const char *_ = (T);						\
    struct svalue *_sp_ = Pike_sp++;                                 	\
    _sp_->subtype=0;                                                    \
    _sp_->u.string=make_shared_binary_string(_,(int)(n));              	\
    debug_malloc_touch(_sp_->u.string);                                 \
    _sp_->type=PIKE_T_STRING;                                           \
  }while(0)

%%{
    machine PSYC;
    write data;

    action parse_key {
	push_n_text(mark, fpc - mark);
	c++;
    }

    action push_val {
	if (fpc - mark > 0) {
            string_builder_binary_strcat(&s, mark, (ptrdiff_t)(fpc - mark));
        }
    }

    action list {
	list++;
    }

    action add_newline {
	string_builder_putchar(&s, '\n');
    }

    action add_list {
	if (list >= 1) {
	    f_aggregate(list+1);
	    c -= list;
	    list = 0;
	}
    }

    action add_last {
	if (lastmod != 0) {
	    push_string(finish_string_builder(&s));
	    init_string_builder(&s, 1);
	    c++;
	}
    }

    action curmod { lastmod = mod; mod = fc; }
    action mark { mark = fpc; }
    action markprev { mark = fpc-1; }
    action checkmod { if (lastmod == 0) Pike_error("Invalid variable/list continuation."); }
    action checkmod_equal {
	if (mod =! lastmod) {
	    Pike_error("Continuation of variable (modifier: '%c') with different modifier '%c'.", lastmod, mod);
	}
    }

    method = '_' . (alnum | '_')+;
    modifier = [:=+-?];
    value = (any - '\n');
    var = method >markprev %parse_key. '\t' . value* >mark %push_val . '\n';
    continuation = '\t' >checkmod . value* >mark %push_val . '\n';
    header_line = ((modifier >curmod . (var >add_list | continuation >checkmod_equal %list) >add_last) | continuation >add_newline);
    main := header_line* . method >add_last >mark . '\n' %*{ fbreak; };
}%%

/*! @module Public
 */

/*! @module Parser
 */

/*! @module PSYC
 */

/*! @decl object parse(string s)
 *!
 *! Parses a JSON-formatted string and returns the corresponding mapping.
 */
PIKEFUN object parse(string data) {
    char *p, *pe, *mark;
    int c = 0;
    int list = 0;
    int cs;
    char lastmod = 0, mod = 0;
    // we wont be building more than one string at once.
    struct string_builder s;
    struct program *prog;

    // length n can be alot but is certainly enough.
    init_string_builder(&s, 1);

    pop_stack();

    push_text("PSYC.Packet");
    SAFE_APPLY_MASTER("resolv", 1);

    if (((struct svalue *)(Pike_sp - 1))->type != PIKE_T_PROGRAM) {
	Pike_error("Could not resolv program PSYC.Packet.\n");
    }

    prog = ((struct svalue *)(Pike_sp - 1))->u.program;

    pop_stack();

    p = (char*)STR0(data);
    pe = p + data->len;

    %%
    %% write init;
    %% write exec;

    if (cs < PSYC_first_final) {
	Pike_error("Error parsing PSYC packet.\n");
    }

    f_aggregate_mapping(c);

    push_n_text(mark, p - 1 - mark);

    stack_swap(); // its mc, vars, data

    if (pe - p > 0) {
	push_n_text(p, pe - p);
    } else {
	push_string(empty_pike_string);
    }

    push_object(debug_clone_object(prog, 3));
}


