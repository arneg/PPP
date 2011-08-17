UTIL.Base64 = {
    char64 : "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/",
    encode : function(s) {
	var len = Math.floor(s.length/3);
	var r = s.length % 3;
	var ret = new Array(len + (!!r ? 1 : 0));
	var c1, c2, c3;
	var m = UTIL.Base64.char64;

	for (var i = 0; i < len; i++) {
	    c1 = s.charCodeAt(i*3);
	    c2 = s.charCodeAt(i*3+1);
	    c3 = s.charCodeAt(i*3+2);

	    ret[i] = String.fromCharCode(m.charCodeAt(c1>>2),
					 m.charCodeAt((c1&3)<<4 | c2>>4),
					 m.charCodeAt((c2&15)<<2 | c3 >> 6),
					 m.charCodeAt(c3&63));
	}

	var c1 = s.charCodeAt(s.length - 2);

	if (r == 2) {
	    var c2 = s.charCodeAt(s.length - 1);

	    ret[ret.length-1] = String.fromCharCode(m.charCodeAt(c1>>2), m.charCodeAt((c1&3<<4)| c2 >> 4), m.charCodeAt(c2&15)<<2) + "=";
	} else if (r == 1) {
	    ret[ret.length-1] = String.fromCharCode(m.charCodeAt(c1>>2), m.charCodeAt(c1&3<<4)) + "==";
	}

	return ret.join("");
    },
    deco : function(i) {
	i = UTIL.Base64.deco64[i];
	if (!i) throw("holy cow!\n");
	return i - 1;
    },
    // TODO: this should maybe collect the integers and do one
    // call to String.fromCharCode at the end.
    decode : function(b) {
	var res = [];
	var i = 0;
	var s;
	var next;

	b = b.replace(/\n/g, "").replace(/\r/g, "");
	s = b.length;
	//alert(b + "!!" + b.length);

	while (i +4 <= s) {
	    res.push(String.fromCharCode((UTIL.Base64.deco(b.charCodeAt(i)) << 2) | (UTIL.Base64.deco(b.charCodeAt(i+1)) >> 4)));
	    next = ((UTIL.Base64.deco(b.charCodeAt(i+1)) << 4) & 0xff) | (UTIL.Base64.deco(b.charCodeAt(i+2)) >> 2);
	    if (next || b.charAt(i+2) != "=") {
		res.push(String.fromCharCode(next));
	    } else {
		return res.join("");
	    }
	    
	    next = ((UTIL.Base64.deco(b.charCodeAt(i+2)) << 6) & 0xc0) | UTIL.Base64.deco(b.charCodeAt(i+3));
	    if (next || b.charAt(i+3) != "=") {
		res.push(String.fromCharCode(next));
	    } else {
		return res.join("");
	    }

	    i += 4;
	}

	return res.join("");
    },

    decode_to_int : function(b) {
	var res = [];
	var i = 0;
	var s;
	var next;

	b = b.replace(/\n/g, "").replace(/\r/g, "");
	s = b.length;
	//alert(b + "!!" + b.length);

	while (i +4 <= s) {
	    res.push((UTIL.Base64.deco(b.charCodeAt(i)) << 2) | (UTIL.Base64.deco(b.charCodeAt(i+1)) >> 4));
	    next = ((UTIL.Base64.deco(b.charCodeAt(i+1)) << 4) & 0xff) | (UTIL.Base64.deco(b.charCodeAt(i+2)) >> 2);
	    if (next || b.charAt(i+2) != "=") {
		res.push(next);
	    } else {
		return res;
	    }
	    
	    next = ((UTIL.Base64.deco(b.charCodeAt(i+2)) << 6) & 0xc0) | UTIL.Base64.deco(b.charCodeAt(i+3));
	    if (next || b.charAt(i+3) != "=") {
		res.push(next);
	    } else {
		return res;
	    }

	    i += 4;
	}

	return res;
    }
};
UTIL.Base64.deco64 = (function() {
	var x = {};
	var i;

	for (i = 0; i < 64; ++i) {
	    x[UTIL.Base64.char64.charCodeAt(i)] = i + 1;
	}

	x["=".charCodeAt(0)] = 1;

	return x;
   })();
