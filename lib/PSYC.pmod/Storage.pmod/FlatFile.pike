#include <debug.h>
inherit .MappingBased;

string filename;
int autosave;

string encode(mixed stuff) {
    return encode_value(stuff);
}

mixed decode(string stuff) {
    catch {
	return decode_value(stuff);
    };
}

string readfile() {
    Stdio.File in;
    string ret;

    catch {
	in = Stdio.File(filename, "r");
	ret = in->read();
	in->close();
	autosave = 1;
    };

    return ret;
}

void writefile(string stuff) {
    Stdio.File out;

    Stdio.mkdirhier(dirname(filename));
    out = Stdio.File(filename, "cwt");
    out->write(stuff);
    out->close();
}

void create(string file) {
    filename = Stdio.simplify_path(file);

    if (filename[0] != '/') filename = "./" + filename;

    data = decode(readfile());

    if (!mappingp(data)) data = ([ ]);
}

void save() {
    autosave = 1;
    writefile(encode(data));
}

void destroy() {
    if (autosave && catch { save(); }) {
	P0(("PSYC.Storage.FlatFile", "could not write to %O in destroy()\n", filename))
    }
}
