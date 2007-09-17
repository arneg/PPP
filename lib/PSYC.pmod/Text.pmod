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

//! Base TextDB class.
class TextDB {
    mapping fmts = ([ ]);

    //! Get the (already fetched) template from the TextDB.
    //! @seealso
    //! 	@[FileTextDB.fetch()]
    string `[](string mc) {
	return fmts[mc];
    }

    //! Asynchronously fetch a template from the TextDB.
    //! @param mc
    //! 	Message Class of the wanted template.
    //! @param cb
    //! 	callback to be called once the template has been successfully fetched from the template-DB
    //! @note
    //! 	Abstract in this class, needs to be overloaded.
    void fetch(string mc, function cb, mixed ... extra);
}

//! Standard TextDB class that reads templates from the classical psycmuve template directories.
class FileTextDB {
    inherit TextDB;

    string tdbpath;

    //! @param path
    //! 	Path to the TextDB folder.
    //! @note
    //! 	You usually won't have to create your own @[FileTextDB]s, but use @[FileTextDBFactoryFactory()]
     void create(string path) {
 	P3(("FileTextDB", "create(%O)\n", path))
	tdbpath = path;

	if (path[-1] != '/') {
	    path += "/";
	}
    }

    //! Asynchronously fetch a template from the TextDB.
    //! @param mc
    //! 	Message Class of the wanted template.
    //! @param cb
    //! 	callback to be called once the template has been successfully fetched from the template-DB.
    //! 	The arguments to the callback will be an @expr{int(0..1) success@}, followed by expanded @expr{extra@}.
    //! @param extra
    //! 	Arguments to be passed on to the callback.
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
	call_out(cb, 0, 1, @extra);
    }
}

//! Creates a factory which will return @[TextDB] objects for the then-given @expr{lang@} and @expr{scheme@}.
//! @param basepath
//! 	The basepath of the PSYCMuve-like classical TextDB.
//!
//! 	Such directories need to contain subdirectories @expr{$lang/$scheme@}.
//! 	A DB lookup then looks for @expr{$baseurl/$lang/$scheme/ + replace($mc, "_", "/") + .fmt@}.
function(string, string : FileTextDB) FileTextDBFactoryFactory(string basepath) {
    FileTextDB _fun(string scheme, string lang) {
	return FileTextDB(basepath + "/" + Stdio.simplify_path(lang) + "/" + Stdio.simplify_path(scheme));
    };

    return _fun;
}
