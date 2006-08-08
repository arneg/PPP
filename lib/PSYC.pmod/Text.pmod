// vim:syntax=lpc

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
	    va["[(" + m + ")]"] = replace((string)vars[m],
					    ({ "\n", "\r" }),
					    ({ "<br />", "" }));
	    va["[" + m + "]"] = (string)vars[m];
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
