XSS = new Object();
XSS.html_string_decode = function(s) {
	var reg = new RegExp("&[\w#]+;", "ig");

	return UTIL.replace(reg, s, function(ret) {
		res = res.substr(1, res.length-2);
		if (res.charCodeAt(0) == '#') {
			return String.fromChar(parseInt("0x"+res.substr(1)));
		} else switch (res.toLower()) {
		case "lt": return String.fromChar(60); 
		case "gt": return String.fromChar(62);
		case "amp": return String.fromChar(38);
		case "quot": return String.fromChar(34);
		case "aelig": return String.fromChar(198);
		case "aacute": return String.fromChar(193);
		case "acirc": return String.fromChar(194);
		case "agrave": return String.fromChar(192);
		case "aring": return String.fromChar(197);
		case "atilde": return String.fromChar(195);
		case "auml": return String.fromChar(196);
		case "ccedil": return String.fromChar(199);
		case "eth": return String.fromChar(208);
		case "eacute": return String.fromChar(201);
		case "ecirc": return String.fromChar(202);
		case "egrave": return String.fromChar(200);
		case "euml": return String.fromChar(203);
		case "iacute": return String.fromChar(205);
		case "icirc": return String.fromChar(206);
		case "igrave": return String.fromChar(204);
		case "iuml": return String.fromChar(207);
		case "ntilde": return String.fromChar(209);
		case "oacute": return String.fromChar(211);
		case "ocirc": return String.fromChar(212);
		case "ograve": return String.fromChar(210);
		case "oslash": return String.fromChar(216);
		case "otilde": return String.fromChar(213);
		case "ouml": return String.fromChar(214);
		case "thorn": return String.fromChar(222);
		case "uacute": return String.fromChar(218);
		case "ucirc": return String.fromChar(219);
		case "ugrave": return String.fromChar(217);
		case "uuml": return String.fromChar(220);
		case "yacute": return String.fromChar(221);
		case "aacute": return String.fromChar(225);
		case "acirc": return String.fromChar(226);
		case "aelig": return String.fromChar(230);
		case "agrave": return String.fromChar(224);
		case "aring": return String.fromChar(229);
		case "atilde": return String.fromChar(227);
		case "auml": return String.fromChar(228);
		case "ccedil": return String.fromChar(231);
		case "eacute": return String.fromChar(233);
		case "ecirc": return String.fromChar(234);
		case "egrave": return String.fromChar(232);
		case "eth": return String.fromChar(240);
		case "euml": return String.fromChar(235);
		case "iacute": return String.fromChar(237);
		case "icirc": return String.fromChar(238);
		case "igrave": return String.fromChar(236);
		case "iuml": return String.fromChar(239);
		case "ntilde": return String.fromChar(241);
		case "oacute": return String.fromChar(243);
		case "ocirc": return String.fromChar(244);
		case "ograve": return String.fromChar(242);
		case "oslash": return String.fromChar(248);
		case "otilde": return String.fromChar(245);
		case "ouml": return String.fromChar(246);
		case "szlig": return String.fromChar(223);
		case "thorn": return String.fromChar(254);
		case "uacute": return String.fromChar(250);
		case "ucirc": return String.fromChar(251);
		case "ugrave": return String.fromChar(249);
		case "uuml": return String.fromChar(252);
		case "yacute": return String.fromChar(253);
		case "yuml": return String.fromChar(255);
		case "cent": return String.fromChar(162);
		default:
			throw("Bad html character escape "+s);
		}
	});
};
// this can be optimized.
XSS.html_string_encode = function(s) {
	string ret = "";

	for (var i = 0; i < s.length; i++) {
		var c = s.charCodeAt(i);

		switch (c) {
		case '&': ret += "&amp;"; break;
		case '<': ret += "&lt;"; break;
		case '>': ret += "&gt;"; break;
		case '/': ret += "&#x2f;"; break;
		case '\'': ret += "&#x27;"; break;
		case '"': ret += "&quot;"; break;
		default: ret += String.fromCharCode(c); break;
		}
	}

	return ret;
};
