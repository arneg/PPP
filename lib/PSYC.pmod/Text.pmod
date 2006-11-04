// vim:syntax=lpc
#include <debug.h>
#define unless(x)	if(!(x))
#define member	has_index

string psyctext(string fmt, mapping|void vars) {
    if (vars) {
	string before, cond, body, after, before2, after2;
	mapping va = ([ ]);
	mixed t;

	while (sscanf(fmt, "%s[if _%s]%s[fi]%s",
		      before, cond, body, after) == 4) {
	    if (sscanf(body, "%s[else]%s", before2, after2) == 2) {
		if ((t = vars["_" + cond]) && t != "" && t != "0") {
		    fmt = before + before2 + after;
		} else {
		    fmt = before + after2 + after;
		}
	    } else {
		if ((t = vars["_" + cond]) && t != "" && t != "0") {
		    fmt = before + body + after;
		} else {
		    fmt = before + after;
		}
	    }
	}

	foreach(indices(vars), string m) {
	    mixed val = vars[m];

	    if (arrayp(val)) {
		val = val * ", ";
	    } else if (mappingp(val)) {
		val = sprintf("%O", val);
	    }
#ifdef HTML
	    va["[(" + m + ")]"] = replace((string)vars[m],
					    ({ "\n", "\r" }),
					    ({ "<br />", "" }));
#endif
	    va["[" + m + "]"] = (string)val;
	}

	fmt = replace(fmt, va);
    } else {
	string before, after;

	while (sscanf(fmt, "%s[if _%*s]%*s[fi]%s", before, after) == 4) {
	    fmt = before + after;
	}
    }

    return fmt;
}
//#define NO_CACHE

#define unless(x)	if(!(x))
#define member	has_index

class TextDB {
    mapping fmts = ([ ]);

    string `[](string mc) {
	return fmts[mc];
    }

    void fetch(string mc, function cb, mixed ... extra);
}

class FileTextDB {
    inherit TextDB;

    string tdbpath;

    void create(string path) {
	P3(("FileTextDB", "create(%O)\n", path))
	tdbpath = path;

	if (path[-1] != '/') {
	    path += "/";
	}
    }

    void fetch(string mc, function cb, mixed ... extra) {
	P3(("text", "fetch(%O, %O, %O)\n", mc, cb, extra))
	string filename, fmt, before, match, after;
	Stdio.File file;

	if (member(fmts, mc)) {
	    call_out(cb, 0, 1, @extra);

	    return;
	}

	filename = tdbpath + Stdio.simplify_path(replace(mc, "_", "/")) + ".fmt";

	P3(("Text", "opening %O\n", filename))
	if (Stdio.is_file(filename)) {
	    P3(("Text", "is_file\n"))
	    file = Stdio.File(filename, "r");
	    fmt = file->read();
	    file->close();
	} else {
	    P3(("Text", "else\n"))
	    array(string) l = mc / "_";

	    if (sizeof(l) > 2) {
		call_out(fetch, 0, l[0.. sizeof(l) - 2] * "_", cb, @extra);

		return;
	    }
	    call_out(cb, 0, 0, @extra);

	    return;
	}

#if 0 // TODO:: add to "unfeatured" document
	while (sscanf(fmt, "%s{_%s}%s", before, match, after) == 3) {
	    fmt = before + `[]("_" + match) + after;
	}
#endif

	fmts[mc] = fmt;
	P3(("Text", "calling_out really soon\n"))
	call_out(cb, 0, 1, @extra);
    }
}

function(string, string : FileTextDB) FileTextDBFactoryFactory(string basepath) {
    FileTextDB _fun(string scheme, string lang) {
	return FileTextDB(basepath + "/" + Stdio.simplify_path(lang) + "/" + Stdio.simplify_path(scheme));
    };

    return _fun;
}
