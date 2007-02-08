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

#define push_n_text(T, n) do {						\
    const char *_ = (T);						\
    struct svalue *_sp_ = Pike_sp++;                                 	\
    _sp_->subtype=0;                                                    \
    _sp_->u.string=make_shared_binary_string(_,n);              	\
    debug_malloc_touch(_sp_->u.string);                                 \
    _sp_->type=PIKE_T_STRING;                                           \
  }while(0)

%%{
    machine psyc;
    write data;

    action parse_key {
	push_n_text(mark, (ptrdiff_t)(fpc - mark));
	c++;
    }

    action push_val {
	if (fpc - mark > 0) {                                                                                                         
            string_builder_binary_strcat(s, mark, (ptrdiff_t)(fpc - mark));                                                           
        }
    }

    action list {
	list++;
    }

    action add_newline {
	string_builder_putchar(s, '\n');
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
	    push_string(finish_string_builder(s));
	    inti_string_builder(s, 1);
	    c++;
	}
    }

    action curmod { lastmod = mod; mod = fc; }
    action mark { mark = fpc; }
    action markprev { mark = fpc-1; }
    action checkmod { if (lasmod == 0) Pike_error("Invalid variable/list continuation."); }
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
PIKEFUN object parse(string data, object o) {
    char *p, *pe, *mark;
    int c = 0;
    int list = 0;
    int done = 0;
    char lastmod = 0, mod = 0;
    // we wont be building more than one string at once.
    struct string_builder s;

    // length n can be alot but is certainly enough.
    init_string_builder(&s, 1);

    p = (char*)STR0(data);
    pe = p + data->len;

    %%
    %% write init;
    %% write exec;

    if (cs < PSYC_first_final) {
	Pike_error("Error parsing PSYC packet.\n");
    }

    f_aggregate_mapping(c);

    c = find_identifier("mc", prog);
    object_low_set_index(o, c, );

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


