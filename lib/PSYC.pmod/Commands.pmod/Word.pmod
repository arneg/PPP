//! Parse a Word, e.g. a non-whitespace string. Consumes all trailing spaces.
//! Argument may be an Integer for fixed length words. 

array parse(string data, object ui, int|void length) {
    if (length) {

	if (length > sizeof(data)) {
	    return ({ 0, "Input too short." });
	}
	if (sizeof(data) > length && data[length] != ' ') {
	    return ({ 0, "Word is too long."});
	}
    } else {
	length = search(data, " ");
	if (length == -1) {
	    return ({ sizeof(data), data});
	}
    }

    int size = length;
    while (sizeof(data) > size && data[++size] == ' ');
    return ({ size, data[0 .. length - 1] });
}

