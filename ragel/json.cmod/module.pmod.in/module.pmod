
//! @ignore
inherit @module@;
//! @endignore

constant __author = "Arne Goedeke <pike@laramies.com>";
constant __version = "0.2";

constant ASCII_ONLY = 1;
constant ASCII_LESS = 3;
constant HUMAN_READABLE = 4;
//! May be passed to @[render()] as the second argument. Multiple
//! flags may be used by ORing them bitwise (ASCII_LESS includes
//! ASCII_ONLY).
//! 
//! @int
//! 	@value ASCII_ONLY
//! 		Render all Unicode characters in strings with value
//! 		bigger than 255 using the \u escape.
//! 	@value ASCII_LESS
//! 		Renders all Unicode character in strings with value outside
//! 		of 32 - 126 using the \u escape.
//! 	@value HUMAN_READABLE
//! 		Uses spaces and tabs to create easy to read output.
//! @endint

//! @decl string render(mixed data, int flags)
//! @decl String.Buffer render(mixed data, int flags, String.Buffer buf)
//!
//! Takes a native pike data structure (no multisets allowed and all mappings
//! need strings as keys) and renders it into a string/String.Buffer.
//! 
//! @throws
//! 	Throws an exception in case the data contains multisets or a
//! 	mapping with non-string keys.
//! 
object|string render(mixed data, int flags, void|object buf, void|int level) {
    int r = 0;
    
    if (multisetp(data)) {
	throw(({ "The data structure contains a multiset and therefore cannot be rendered into JSON." }));
    }

    if (!level) level = 0;
    if (!buf) {
	r = 1;
	buf = String.Buffer();
    }
    function add = buf->add;
    function put = buf->putchar;

    if (stringp(data)) {
	put('"');
	foreach (data;;int char) {
	    switch(char) {
	    case '"': add("\\\""); break;
	    case '\\': add("\\\\"); break;
	    case '/': add("\\/"); break;
	    case '\b': add("\\b"); break;
	    case '\t': add("\\t"); break;
	    case '\n': add("\\n"); break;
	    case '\f': add("\\f"); break;
	    case '\r': add("\\r"); break;
	    case 0 .. 7:
	    case 11:
	    case 14 .. 31:
	    case 127 .. 255:
		if (flags & ASCII_LESS) {
		    add(sprintf("\\u%04x", char);	    
		} else {
		    put(char);	    
		}
		break;
	    default:
		if (char > 255 && flags & ASCII_ONLY) {
		    add(sprintf("\\u%04x", char);	    
		} else {
		    put(char);
		}
	    }
	}
	put('"');
    } else if (mappingp(data)) {
	if (flags & HUMAN_READABLE && level) add(("\t" * level));
	put('{');
	if (flags & HUMAN_READABLE && level) put('\n');
	int num = sizeof(data);
	level ++;
	foreach (data; mixed key; mixed value) {
	    if (!stringp(key)) {
		throw(({ "The data structure contains a mapping with non-string keys and therefore cannot be rendered into JSON." }));
	    }

	    if (flags & HUMAN_READABLE) add(("\t" * level));
	    render(key, flags, buf, level);
	    if (flags & HUMAN_READABLE) put(' ');
	    put(':');
	    if (flags & HUMAN_READABLE) put(' ');
	    render(value, flags, buf, level);
	    if (--num != 0) put(',');
	    if (flags & HUMAN_READABLE) put('\n');
	}
	level --;
	if (flags & HUMAN_READABLE && level) add(("\t" * level));
	put('}');
    } else if (arrayp(data)) {
	if (flags & HUMAN_READABLE && level) add(("\t" * level));
	put('[');
	int num = sizeof(data);
	level ++;
	foreach (data; ;mixed value) {
	    if (flags & HUMAN_READABLE) add(("\t" * level));
	    render(value, flags, buf, level);
	    if (--num != 0) put(',');
	    if (flags & HUMAN_READABLE) put('\n');
	}
	level --;
	if (flags & HUMAN_READABLE && level) add(("\t" * level));
	put(']');
    } else if (intp(data)) {
	add((string)data);
    } else if (floatp(data)) {
	add((string)data);
    } else {
	throw(({ "This type cannot be rendered into JSON." }));
    }

    if (r) {
	return buf;
    }

    return buf->get();
}
