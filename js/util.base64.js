UTIL.Base64 = {
    deco64 : (function() {
		    var x = {};
		    var char64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
		    var i;

		    for (i = 0; i < 64; ++i) {
			x[char64.charCodeAt(i)] = i + 1;
		    }

		    x["=".charCodeAt(0)] = 1;

		    return x;
	       })(),

    deco : function(i) {
	i = UTIL.Base64.deco64[i];
	if (!i) throw("holy cow!\n");
	return i - 1;
    },

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
