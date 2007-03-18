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
#include "array.h"
#include "builtin_functions.h"
#include "module.h"

p_wchar2 *_parse_JSON(p_wchar2* p, p_wchar2* pe, short validate); 
p_wchar2 *_parse_JSON_mapping(p_wchar2* p, p_wchar2* pe, short validate); 
p_wchar2 *_parse_JSON_array(p_wchar2* p, p_wchar2* pe, short validate); 
p_wchar2 *_parse_JSON_number(p_wchar2* p, p_wchar2* pe, short validate); 
p_wchar2 *_parse_JSON_string(p_wchar2* p, p_wchar2* pe, short validate); 

#include "json_string.c"
#include "json_number.c"
#include "json_array.c"
#include "json_mapping.c"

%%{
    machine JSON;
    alphtype int;
    write data;

    action parse_string {
	i = _parse_JSON_string(fpc, pe, validate);
	if (validate && i == NULL) {
	    return NULL;
	}
	fexec i;
    }

    action parse_mapping {
	i = _parse_JSON_mapping(fpc, pe, validate);
	if (validate && i == NULL) {
	    return NULL;
	}
	fexec i;
    }

    action parse_array {
	i = _parse_JSON_array(fpc, pe, validate);
	if (validate && i == NULL) {
	    return NULL;
	}
	fexec i;
    }

    action parse_number {
	i = _parse_JSON_number(fpc, pe, validate);
	if (validate && i == NULL) {
	    return NULL;
	}
	fexec i;
    }

    number_start = [\-+.] | digit;
    array_start = '[';
    mapping_start = '{';
    string_start = '"';
    value_start = number_start | array_start | mapping_start | string_start;
    myspace = [ \n\r\t];

    main := myspace* . (number_start >parse_number |
			string_start >parse_string |
			mapping_start >parse_mapping |
			array_start >parse_array |
			'true' @{ if (!validate) push_int(1); } |
			'false' @{ if (!validate) push_undefined(); } |
			'null' @{ if (!validate) push_int(0); } ) . myspace* %*{ fbreak; };
}%%

p_wchar2 *_parse_JSON(p_wchar2 *p, p_wchar2 *pe, short validate) {
    p_wchar2 *i = p;
    int cs;

    %% write init;
    %% write exec;

    if (cs >= JSON_first_final) {
	return p;
    }

    if (!validate) {
	Pike_error("Error parsing JSON at '%c'\n", (char)*p);
    }

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
 *! Have a look at 
 *! 
 *! @[http://www.json.org] or 
 *! 
 *! @[http://www.ietf.org/rfc/rfc4627.txt?number=4627] for
 *! information about what JSON is.
 */

/*! @decl int validate(string s)
 *!
 *! Takes a string and checks if it is valid JSON.
 *! 
 *! @returns
 *! 	In case the string contains valid JSON. It is then guarenteed to be parsed
 *! 	without errors by @[parse()].
 *! 	In case the string is not valid JSON, the integer position inside the string
 *! 	where the error occures is returned.
 */
PIKEFUN int validate(string data) {
    struct pike_string *b;
    p_wchar2 *ret;
    // we wont be building more than one string at once.

    switch (data->size_shift != 0) {
    case 0:
	b=begin_wide_shared_string(data->len,2);
        convert_0_to_2(STR2(b),(p_wchar0 *)data->str,data->len);
	free_string(data);
	end_shared_string(b);
	break;
    case 1:
	b=begin_wide_shared_string(data->len,2);
        convert_1_to_2(STR2(b),STR1(data),data->len);
	free_string(data);
	end_shared_string(b);
	break;
    case 2:
	b = data;
	break;
    }

    pop_stack();
    ret = STR2(b);
    if (_parse_JSON(ret, ret + b->len, 1) == NULL) {
	push_int((int)ret);
	stack_swap();
	f_minus(2);
    } else {
	push_int(-1);
    }
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
    struct pike_string *b;
    p_wchar2 *ret;
    // we wont be building more than one string at once.

    switch (data->size_shift != 0) {
    case 0:
	b=begin_wide_shared_string(data->len,2);
        convert_0_to_2(STR2(b),(p_wchar0 *)data->str,data->len);
	free_string(data);
	end_shared_string(b);
	break;
    case 1:
	b=begin_wide_shared_string(data->len,2);
        convert_1_to_2(STR2(b),STR1(data),data->len);
	free_string(data);
	end_shared_string(b);
	break;
    case 2:
	b = data;
	break;
    }

    pop_stack();
    ret = STR2(b);
    ret = _parse_JSON(ret, ret + b->len, 0);
    return;
}

/*! @endmodule
 */
/*! @endmodule
 */
/*! @endmodule
 */
