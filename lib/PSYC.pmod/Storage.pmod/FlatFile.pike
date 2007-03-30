#include <debug.h>

//! This class provides a mapping-like structure that gets serialized to a
//! file.

inherit .MappingBased;

string filename;
int autosave;
object codec;

string encode(mixed stuff) {
    return encode_value(stuff, codec);
}

mixed decode(string stuff) {
    if (stuff)
	return decode_value(stuff, codec);
    else 
	return 0;
}

string readfile() {
    Stdio.File in;
    string ret;
    mixed err;

    if (Stdio.is_file(filename)) {
	mixed err = catch {
	in = Stdio.File(filename, "r");
	ret = in->read();
	in->close();
	autosave = 1;
	};
	if (err)
	    P0(("FlatFile", "Reading %O failed: %O.\n", filename, err))
    }

    return ret;
}

void writefile(string stuff) {
    Stdio.File out;

    Stdio.mkdirhier(dirname(filename));
    out = Stdio.File(filename, "cwt");
    out->write(stuff);
    out->close();
}

//! @param file
//! 	Path to the file to write to.
//! @param codec_object
//! 	Codec object to use for serialization. Is used for
//! 	@[MMP.Uniform] object only right now.
void create(string file, object codec_object) {
    filename = Stdio.simplify_path(file);
    codec = codec_object;

    if (filename[0] != '/') filename = "./" + filename;

    data = decode(readfile());

    if (!mappingp(data)) data = ([ ]);
}

//! Sync to disk.
//! @note
//! 	The first @[save()] will cause the file to be autosaved on destruct.
void save() {
    P2(("PSYC.Storage.FlatFile", "i'll save %O, i'll do it, don't try to stop me!\n", filename))
    autosave = 1;
    writefile(encode(data));
}

void destroy() {
    if (autosave && catch { save(); }) {
	P0(("PSYC.Storage.FlatFile", "could not write to %O in destroy()\n", filename))
    }
    P0(("FlatFile", "destroy()\n"))
}

