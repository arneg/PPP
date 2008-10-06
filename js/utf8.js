UTF8 = new Object();
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
UTF8.legacy_decode =        function(utftext) {
            var plaintext = ""; var i=0; var c=c1=c2=0;
            // while-Schleife, weil einige Zeichen uebersprungen werden
            while(i<utftext.length)
                {
                c = utftext.charCodeAt(i);
                if (c<128) {
                    plaintext += String.fromCharCode(c);
                    i++;}
                else if((c>191) && (c<224)) {
                    c2 = utftext.charCodeAt(i+1);
                    plaintext += String.fromCharCode(((c&31)<<6) | (c2&63));
                    i+=2;}
                else {
                    c2 = utftext.charCodeAt(i+1); c3 = utftext.charCodeAt(i+2);
                    plaintext += String.fromCharCode(((c&15)<<12) | ((c2&63)<<6) | (c3&63));
                    i+=3;}
                }
            return plaintext;
};
UTF8.legacy_encode = function(rohtext) {
            // dient der Normalisierung des Zeilenumbruchs
            var utftext = "";
            for(var n=0; n<rohtext.length; n++)
                {
                // ermitteln des Unicodes des  aktuellen Zeichens
                var c=rohtext.charCodeAt(n);
                // alle Zeichen von 0-127 => 1byte
                if (c<128)
                    utftext += String.fromCharCode(c);
                // alle Zeichen von 127 bis 2047 => 2byte
                else if((c>127) && (c<2048)) {
                    utftext += String.fromCharCode((c>>6)|192);
                    utftext += String.fromCharCode((c&63)|128);}
                // alle Zeichen von 2048 bis 66536 => 3byte
                else {
                    utftext += String.fromCharCode((c>>12)|224);
                    utftext += String.fromCharCode(((c>>6)&63)|128);
                    utftext += String.fromCharCode((c&63)|128);}
                }
            return utftext;
};
