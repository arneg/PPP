// vim:syntax=lpc
// 
// I really hate those comments.
//
// Copyright History:
// 1. Public Domain 2002 JSON.org
// 2. Ported to C# by Are Bjolseth, teleplan.no
// 3. Ported to pike by Bill Welliver
//    "Last night, I downloaded the JSON-C# code, and converted it to pike
//    (with relatively little effort, it was mostly a tedious reformatting
//    job)."
// 4. Adopted by Tobias 'tobij' Josefowitz, now uses Pike datastructures
//
// As far as I am concerned, this still is Public Domain.
// I will probably once find out whether Are and Bill think the same wwy
// about it.

/// <summary>
/// <para>
///  A JSONTokener takes a source string and extracts characters and tokens from
///  it. It is used by the JSONObject and JSONArray constructors to parse
///  JSON source strings.
///  </para>
///  <para>
///  Public Domain 2002 JSON.org
///  @author JSON.org
///  @version 0.1
///  </para>
///  <para>Ported to C# by Are Bjolseth, teleplan.no</para>
///  <para>
///  <list type="bullet">
///  <item><description>Implement Custom exceptions</description></item>
///  <item><description>Add unit testing</description></item>
///  <item><description>Add log4net</description></item>
///  </list>
///  </para>
/// </summary>
/// <summary>The index of the next character.</summary>
int myIndex;
/// <summary>The source string being tokenized.</summary>
string mySource;


#ifdef __PIKE__
# define THROW(x)	throw(Error.Generic(x))
program objectbuilder, arraybuilder;
#else
# define arrayp(x)	pointerp(x)
# define THROW(x)	raise_error(x)
#endif

/// <summary>
/// Construct a JSONTokener from a string.
/// </summary>
/// <param name="s">A source string.</param>
#ifdef __PIKE__
static void create(string s, program|void objectb, program|void arrayb)
#else
varargs void create(string s)
#endif
{
	myIndex = 0;
	mySource = s;
#ifdef __PIKE__
	objectbuilder = objectb;
	arraybuilder = arrayb;
#endif
}

/// <summary>
/// Back up one character. This provides a sort of lookahead capability,
/// so that you can test for a digit or letter before attempting to parse
/// the next number or identifier.
/// </summary>
public void back() {
	if (myIndex > 0)
		myIndex -= 1;
}

/// <summary>
/// Get the hex value of a character (base16).
/// </summary>
/// <param name="c">
/// A character between '0' and '9' or between 'A' and 'F' or
/// between 'a' and 'f'.
/// </param>
/// <returns>An int between 0 and 15, or -1 if c was not a hex digit.</returns>
public static int dehexchar(int c) {
	if (c >= '0' && c <= '9') 
	{
		return c - '0';
	}
	if (c >= 'A' && c <= 'F') 
	{
		return c + 10 - 'A';
	}
	if (c >= 'a' && c <= 'f') 
	{
		return c + 10 - 'a';
	}
	return -1;
}

/// <summary>
/// Determine if the source string still contains characters that next() can consume.
/// </summary>
/// <returns>true if not yet at the end of the source.</returns>
public int more() {
	return myIndex < sizeof(mySource);
}

/// <summary>
/// Get the next character in the source string.
/// </summary>
/// <returns>The next character, or 0 if past the end of the source string.</returns>
#ifdef __PIKE__
public int next(int|void x)
#else
varargs public int next(int x)
#endif
{
   if(x) {
	int n = next();

	if (n != x) {
		THROW("Expected '" + x + "' and instead saw '" + n + "'.\n");
	}

	return n;
    } else {
	int c = more() ? mySource[myIndex] : 0;

	myIndex += 1;
	return c;
    }
}


/// <summary>
/// Get the next n characters.
/// </summary>
/// <param name="n">The number of characters to take.</param>
/// <returns>A string of n characters.</returns>
public string nextn(int n) {
	int i = myIndex;
	int j = i + n;

	if (j >= sizeof(mySource)) {
		THROW("Substring bounds error\n");
	}
	myIndex += n;
	return mySource[i..j];
}

/// <summary>
/// Get the next char in the string, skipping whitespace
/// and comments (slashslash and slashstar).
/// </summary>
/// <returns>A character, or 0 if there are no more characters.</returns>
public int nextClean() {
	while (1) {
		int c = next();
		if (c == '/') {
			switch (next()) {
				case '/':
					do {
						c = next();
					} while (c != '\n' && c != '\r' && c != 0);
					break;
				case '*':
					while (1) {
						c = next();

						if (c == 0) {
							THROW("Unclosed comment.\n");
						}

						if (c == '*') {
							if (next() == '/') {
								break;
							}

							back();
						}
					}

					break;
				default:
					back();
					return '/';
			}
		} 
		else if (c == 0 || c > ' ') {
			return c;
		}
	}
}

/// <summary>
/// Return the characters up to the next close quote character.
/// Backslash processing is done. The formal JSON format does not
/// allow strings in single quotes, but an implementation is allowed to
/// accept them.
/// </summary>
/// <param name="quote">The quoting character, either " or '</param>
/// <returns>A String.</returns>
public string nextString(int quote) {
	int c;
	String.Buffer sb = String.Buffer();
	while (1) {
		c = next();
		if ((c == 0x00) || (c == 0x0A) || (c == 0x0D)) {
			throw (Error.Generic("Unterminated string"));
		}
		// CTRL chars
		if (c == '\\') {
			c = next();
			switch (c) {
				case 'b': //Backspace
					sb+=("\b");
					break;
				case 't': //Horizontal tab
					sb+=("\t");
					break;
				case 'n':  //newline
					sb+=("\n");
					break;
				case 'f':  //Form feed
					sb+=("\f");
					break;
				case 'r':  // Carriage return
					sb+=("\r");
					break;
				case 'u':
					int iascii;
					sscanf(nextn(4), "%4x", iascii);
					sb+=String.int2char(iascii);
					break;
				default:
					sb+=String.int2char(c);
					break;
			}
		} else {
			if (c == quote) {
				return sb->get();
			}
			sb+=String.int2char(c);
		}
	}//END-while
}

/// <summary>
/// Get the text up but not including the specified character or the
/// end of line, whichever comes first.
/// </summary>
/// <param name="d">A delimiter character.</param>
/// <returns>A string.</returns>
public string nextTo(int|string d) {
 
     if(intp(d)) {
	String.Buffer sb = String.Buffer();
	while (1) {
		int c = next();
		if (c == d || c == 0 || c == '\n' || c == '\r') {
			if (c != 0) {
				back();
			}
			return String.trim_whites(sb->get());
		}
		sb+=String.int2char(c);
	}
     }    

     else if(stringp(d)) {
	int c;
	String.Buffer sb = String.Buffer();
	while (1) {
		c = next();
		if ((d[c] >= 0) || (c == 0 ) || (c == '\n') || (c == '\r')) {
			if (c != 0) {
				back();
			}
			return String.trim_whites(sb->get());
		}
		sb+=String.int2char(c);
	}
    }
}

mixed jsonObject() {
	mixed addTo = objectbuilder ? objectbuilder() : ([ ]);

	if (next() == '%') {
		unescape();
	}

	back();

	if (nextClean() != '{') {
		throw(Error.Generic("A JSONObject must begin with '{'"));
	}

	while (1) {
		int c;
		string key;
		mixed obj;

		c = nextClean();
		switch (c) {
			case 0:
				throw(Error.Generic("A JSONObject must end "
						    "with '}'\n"));
			case '}':
				return mappingp(addTo) ? addTo : ([object]addTo)->finish();
			case '"':
				back();
				// TODO:: error on != " || '
				key = (string)nextObject();
				break;
			default:
				throw(Error.Generic("Non-String as "
						    "JSONObject-key. That "
						    "is invalid!\n"));
		}

		if (nextClean() != ':') {
			throw(Error.Generic("Expected a ':' after a key\n"));
		}

		obj = nextObject();

		if (mappingp(addTo)) {
		    ([mapping]addTo)[key] = obj;
		} else {
		    ([object]addTo)->add(key, obj);
		}

		switch (nextClean()) {
			case ',':
				if (nextClean() == '}') {
					return mappingp(addTo) ? addTo : ([object]addTo)->finish();
				}

				back();
				break;
			case '}':
					return mappingp(addTo) ? addTo : ([object]addTo)->finish();
			default:
				throw(Error.Generic("Expected a ',' or '}'"));
		}
	}

	return mappingp(addTo) ? addTo : ([object]addTo)->finish();
}

mixed jsonArray() {
	mixed addTo = objectbuilder ? objectbuilder() : ({  });

	if (nextClean() != '[') {
		throw(Error.Generic("A JSONArray must start with '['"));
	}

	if (nextClean() == ']') {
		return arrayp(addTo) ? addTo : ([object]addTo)->finish();
	}

	back();
	while (1) {
		if (arrayp(addTo)) {
		    addTo += ({ nextObject() });
		} else {
		    addTo->add(nextObject());
		}

		switch (nextClean()) 
		{
			case ',':
				if (nextClean() == ']') {
					return arrayp(addTo) ? addTo : ([object]addTo)->finish();
				}
				back();
				break;
			case ']':
					return arrayp(addTo) ? addTo : ([object]addTo)->finish();
			default:
				throw(Error.Generic("Expected a ',' or ']'"));
		}
	}

	return arrayp(addTo) ? addTo : ([object]addTo)->finish();
}

/// <summary>
/// Get the next value as object. The value can be a Boolean, Double, Integer,
/// JSONArray, JSONObject, or String, or the JSONObject.NULL object.
/// </summary>
/// <returns>An object.</returns>
public mixed nextObject() {
	int c = nextClean();
	string s;

	if (c == '"' || c == '\'') {
		return nextString(c);
	}
	// Object
	if (c == '{') {
		back();
		return jsonObject();
	}

	// JSON Array
	if (c == '[') {
		back();
		return jsonArray();
	}

	String.Buffer sb = String.Buffer();

	int b = c;
	while (c >= ' ' && c != ':' && c != ',' && c != ']' && c != '}' && c != '/') {
		sb+=String.int2char(c);
		c = next();
	}
	back();

	s = String.trim_whites(sb->get());
	if (s == "true")
		return 1; 
	if (s == "false")
		return 0;
	if (s == "null")
		return UNDEFINED;

	if ((b >= '0' && b <= '9') || b == '.' || b == '-' || b == '+') {
	   int a; float b; string c;
	   [a, c] = array_sscanf(s, "%d%s");
	   if(c && sizeof(c)) {
	     [b] = array_sscanf(s, "%f");
	     return b;;
	   }
	   else return a;
	}
	if (s == "") {
		THROW("Missing value\n");
	}
	return s;
}

/// <summary>
/// Skip characters until the next character is the requested character.
/// If the requested character is not found, no characters are skipped.
/// </summary>
/// <param name="to">A character to skip to.</param>
/// <returns>
/// The requested character, or zero if the requested character is not found.
/// </returns>
public int skipTo(int to) {
	int c;
	int i = myIndex;
	do {
		c = next();
		if (c == 0) {
			myIndex = i;
			return c;
		}
	}while (c != to);

	back();
	return c;
}

/// <summary>
/// Skip characters until past the requested string.
/// If it is not found, we are left at the end of the source.
/// </summary>
/// <param name="to">A string to skip past.</param>
public void skipPast(string to) {
	myIndex = search(mySource, to, myIndex);
	if (myIndex < 0) {
		myIndex = sizeof(mySource);
	} else {
		myIndex += sizeof(to);
	}
}

// TODO implement exception SyntaxError


/// <summary>
/// Make a printable string of this JSONTokener.
/// </summary>
/// <returns>" at character [myIndex] of [mySource]"</returns>
public string ToString() {
	return " at character " + myIndex + " of " + mySource;
}

/// <summary>
/// Unescape the source text. Convert %hh sequences to single characters,
/// and convert plus to space. There are Web transport systems that insist on
/// doing unnecessary URL encoding. This provides a way to undo it.
/// </summary>

/// <summary>
/// Convert %hh sequences to single characters, and convert plus to space.
/// </summary>
/// <param name="s">A string that may contain plus and %hh sequences.</param>
/// <returns>The unescaped string.</returns>
public string unescape(string|void s) {
	if(!s) s = mySource;
	int len = sizeof(s);
	String.Buffer sb = String.Buffer();
	for (int i=0; i < len; i++) {
		int c = s[i];
		if (c == '+') {
			c = ' ';
		} else if (c == '%' && (i + 2 < len)) {
			int d = dehexchar(s[i+1]);
			int e = dehexchar(s[i+2]);
			if (d >= 0 && e >= 0) {
				c = (d*16 + e);
				i += 2;
			}
		}
		sb+=String.int2char(c);
	}
	return sb->get();
}
