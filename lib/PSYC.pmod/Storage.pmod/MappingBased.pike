mapping data;

array _indices() {
    return indices(data);
}

mixed _m_delete(mixed index) {
    return m_delete(data, index);
}

mixed _search(mixed needle, mixed|void start) {
    return search(data, needle, start);
}

int _sizeof() {
    return sizeof(data);
}

string _sprintf(int format) {
    if (format == 'O') {
	return sprintf("%O(%O)", this_program, data);
    }
}

array _values() {
    return values(data);
}

mixed `[](mixed index) {
    return data[index];
}

mixed `[]=(mixed index, mixed value) {
    return data[index] = value;
}

/*
function (mixed:mixed) `-> = `[];

function (mixed,mixed:mixed) `->= = `[]=;
*/

mixed cast(string type) {
    if (type == "mapping") {
	return copy_value(data);
    }
}

void clear() {
    data = ([ ]);
}
