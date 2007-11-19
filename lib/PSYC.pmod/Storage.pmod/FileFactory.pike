#include <assert.h>

//! Factory for @[PSYC.Storage.File] storage objects.

inherit .Factory;

string basepath;
function namify = aggregate;
object codec_object;

//! @param basepath
//! 	The path where serialized storage should be stored in.
//! @param namify
//! 	A function that may add an aditional layer to the full filename of
//! 	the resulting file, for avoiding overpopulated directories. Signature:
//! 	@expr{array(string) namify(string name)@}.
//! 	@expr{basepath + result * "/"@} will then be the path of the file.
//! @param codec
//! 	Codec object to use for serialization.
void create(string basepath, function|void namify, void|object codec) {
    this_program::basepath = basepath + "/";
    if (namify) this_program::namify = namify;
    codec_object = codec;
    ::create();
}

string char_to_unrelated_word(int c) {
    switch (c) {
	case '~':
	    return "person";
	case '@':
	    return "place";
	case '!':
	    return "service";
	default:
	    return String.int2hex(c);
    }

}

string hexhex(string s) {
    String.Buffer buf = String.Buffer(sizeof(s));
    function add = buf->add, putchar = buf->putchar;

    foreach (s;; int c) {
	switch (c) {
	    case 'a' .. 'z':
	    case 'A' .. 'Z':
	    case '0' .. '9':
	    case '-':
	    case '_':
	    case '[':
	    case ']':
		putchar(c);
		break;
	    default:
		add(sprintf(".%02x.", c));
	}
    }

    return buf->get();
}

object createStorage(MMP.Uniform storagee) {
    String.Buffer buf = String.Buffer();
    
    buf->add(basepath);

    enforce(storagee->is_local());

    if (storagee->resource && sizeof(storagee->resource)) {
	buf->add(char_to_unrelated_word(storagee->resource[0]));
	buf->add("/");
	buf->add(namify(hexhex(storagee->resource[1..]))*"/");
	buf->add(".o");
    } else {
	buf->add("root.o");
    }

    return PSYC.Storage.File(buf->get(), codec_object);
}
