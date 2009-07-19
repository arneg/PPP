/**
 * @namespace
 * UTF8 handling functions.
 */
UTF8 = new Object();
/**
 * @param {String} str Unicode string to be UTF8 encoded.
 * @throws Will throw an error if the string contains non-unicode chars. 
 * @returns The UTF8 encoded string.
 */
UTF8.encode = function(str) {
    var ret = "";
    var mark = 0;
    
    for (var i = 0; i < str.length; i++) {
	var c = str.charCodeAt(i);

	if (c > 0x7f) {
	    if (mark != i) {
		var t = str.substring(mark, i);
		ret += t;
	    }
	    
	    if (c >= 0x80 && c <= 0x07ff) { // 2 byte
		ret += String.fromCharCode(0xc0 | (c>>6), 0x80 | (c & 0x3f)); 
	    } else if ((c >= 0x0800 && c <= 0xd7ff) || (c >= 0xe000 && c <= 0xffff)) { // 3 byte split by non u-chars
		ret += String.fromCharCode(0xe0 | (c>>12), 0x80 | (0x3f & (c>>6)), 0x80 | (c & 0x3f)); 
	    } else if (c >= 0x10000 && c <= 0x10ffff) { // 4 byte
		ret += String.fromCharCode(0xf0 | (c>>18), 0x80 | (0x3f & (c>>12)), x80 | (0x3f & (c>>6)), 0x80 | (c & 0x3f)); 
	    } else {
		throw("trying to encode non-unicode char " + c);
	    }

	    mark = i+1;
	}
    }

    if (mark != str.length) {
	if (mark == 0) {
	    return str;
	} else {
	    ret += str.substring(mark, str.length); 
	}
    }

    return ret;
};
/**
 * @param {String} str UTF8 encoded Unicode string.
 * @throws Will throw an error if the string does not contain valid UTF8.
 * @returns The decoded Unicode string.
 */
UTF8.decode = function(str) {
    var ret = "";
    var mark = 0;
    
    for (var i = 0; i < str.length; i++) {
	var c = str.charCodeAt(i);

	if (c > 0x7f) {
	    if (mark != i) ret += str.substring(mark, i);

	    if (c >= 0xc2 && c <= 0xdf && i+1 < str.length) { // 2 byte
		var c2 = str.charCodeAt(i+1);
		ret += String.fromCharCode(((c & 0x1f) << 6) | (c2 & 0x3f));
		i++;
	    } else if (c >= 0xe0 && c <= 0xef && i+2 < str.length) { // 3 byte
		var c2 = str.charCodeAt(i+1);
		var c3 = str.charCodeAt(i+2);

		ret += String.fromCharCode(((c & 0x0f) << 12) | ((c2 & 0x3f) << 6) | (c3 & 0x3f));

		i+=2;
	    } else if (c >= 0xf0 && c <= 0xf4 && i+3 < str.length) { // 4 byte
		var c2 = str.charCodeAt(i+1);
		var c3 = str.charCodeAt(i+2);
		var c4 = str.charCodeAt(i+3);

		ret += String.fromCharCode(  ((c  & 0x07) << 18) 
					   | ((c2 & 0x3f) << 12) 
					   | ((c3 & 0x3f) << 6) 
					   | (c4 & 0x3f));
		i+=3;
	    } else {
		throw("Invalid UTF8 sequence at pos "+i);
	    }

	    mark = i+1;
	}
    }

    if (mark != str.length) {
	if (mark == 0) {
	    return str;
	} else {
	    ret += str.substring(mark, str.length); 
	}
    }

    return ret;
};
