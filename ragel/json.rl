// vim:syntax=ragel
/* 
 * Pike CMOD parser for JSON.
 * Copyright (C) 2007 Arne Goedeke
 * 
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of version 2.1 of the GNU Lesser General Public
 * License as published by the Free Software Foundation.
 * 
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 *
 */

#include <stdio.h>
#include "global.h"
#include "interpret.h"
#include "stralloc.h"
#include "mapping.h"
#include "svalue.h"
#include "operators.h"
#include "array.h"
#include "builtin_functions.h"
#include "module.h"
#include "gc.h"

p_wchar2 *_parse_JSON(p_wchar2* p, p_wchar2* pe, short validate); 
p_wchar2 *_parse_JSON_mapping(p_wchar2* p, p_wchar2* pe, short validate); 
p_wchar2 *_parse_JSON_array(p_wchar2* p, p_wchar2* pe, short validate); 
p_wchar2 *_parse_JSON_number(p_wchar2* p, p_wchar2* pe, short validate); 
p_wchar2 *_parse_JSON_string(p_wchar2* p, p_wchar2* pe, short validate); 

#include "json_string.c"
#include "json_number.c"
#include "json_array.c"
#include "json_mapping.c"
#include "json.h"

%%{
    machine JSON;
    alphtype int;
    write data;

    number_start = [\-+.] | digit;
    array_start = '[';
    mapping_start = '{';
    string_start = '"';
    value_start = number_start | array_start | mapping_start | string_start;
    myspace = [ \n\r\t];

    main := myspace* . (number_start >{ PARSE(number, fpc); c++; fexec i; } |
			string_start >{ PARSE(string, fpc); c++; fexec i; } |
			mapping_start >{ PARSE(mapping, fpc); c++; fexec i; } |
			array_start >{ PARSE(array, fpc); c++; fexec i; } |
			'true' @{ PUSH_SPECIAL("true"); c++; } |
			'false' @{ PUSH_SPECIAL("false"); c++; } |
			'null' @{ PUSH_SPECIAL("null"); c++; } ) . myspace* %*{ fbreak; };
}%%

p_wchar2 *_parse_JSON(p_wchar2 *p, p_wchar2 *pe, short validate) {
    p_wchar2 *i = p;
    int cs;
    int c = 0;

    %% write init;
    %% write exec;

    if (cs >= JSON_first_final) {
	return p;
    }

    if (!validate && c > 0) pop_n_elems(c);

#ifdef JUMP
    if (!validate) {
	Pike_error("Error parsing JSON at '%c'\n", (char)*p);
    }
#endif

    push_int((int)p);
    return NULL;
}

/*! @module Public
 */

/*! @module Parser
 */

/*! @module JSON2
 *! This module contains a parser to parse JSON into native pike types. The parser has been written
 *! in c using ragel (@[http://www.cs.queensu.ca/~thurston/ragel/]).
 *! The parser is supposed to handle Unicode strings (internally 8, 16 and 32 bit wide strings that is).
 *! 
 *! Have a look at @[http://www.json.org] or @[http://www.ietf.org/rfc/rfc4627.txt?number=4627] for
 *! information about what JSON is.
 */

/*! @decl int validate(string s)
 *!
 *! Takes a string and checks if it is valid JSON.
 *! 
 *! @returns
 *! 	In case the string contains valid JSON @expr{-1@} is returned. It is then guarenteed to be parsed
 *! 	without errors by @[parse()].
 *! 	In case the string is not valid JSON, the integer position inside the string
 *! 	where the error occures is returned.
 */
PIKEFUN int validate(string data) {
    p_wchar2 *ret;
    // we wont be building more than one string at once.

    JSON_CONVERT(data, ret);

    pop_stack();
    if (_parse_JSON(ret, ret + data->len, 1) == NULL) {
	push_int((int)ret);
	f_minus(2);
	push_int(4);
	o_divide();
    } else {
	push_int(-1);
    }

    free(ret);
    return;
}

/*! @decl array|mapping|string|float|int parse(string s)
 *!
 *! Parses a JSON-formatted string and returns the corresponding pike data type.
 *! 
 *! @throws
 *! 	Throws an exception in case the data contained in @expr{s@} is not valid
 *! 	JSON.
 */
PIKEFUN mixed parse(string data) {
    p_wchar2 *ret;
    // we wont be building more than one string at once.
    JSON_CONVERT(data, ret);

    if (_parse_JSON(ret, ret + data->len, 0) == NULL) {
	push_int((int)ret);
	// calculate offset in string where parsing failed
	f_minus(2);
	push_int(4);
	// divide by 4 to get offset in chars
	o_divide();
	push_int(((struct svalue*)(Pike_sp - 1))->u.integer);
	push_int(10);
	// we want 10 chars..
	f_add(2);
	f_index(3);
	free(ret);
	if (((struct svalue*)(Pike_sp - 1))->type != PIKE_T_STRING) {
	    Pike_error("Parsing JSON failed and I dont know where.\n");
	} else {
	    push_text("Parsing JSON failed at '%s'.\n");
	    stack_swap();
	    f_sprintf(2);
	    f_aggregate(1);
	    f_throw(1);
	}
    }

    free(ret);
    stack_pop_keep_top();

    return;
}

/*! @endmodule
 */
/*! @endmodule
 */
/*! @endmodule
 */
