//! This class provides lots of mapping like operators.
//! Is inherited by for exampke @[FlatFile]. Provides basic mapping
//! operations, set, delete, indices, but not more vague things like
//! @[`+()] or @[`&()], since storage classes don't (need to) make use of
//! those.

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

//! Resets the mapping to an empty one.
//! @note
//! 	Keep in mind to overwrite these in subclasses that operate on
//! 	mapping-like structures.
void clear() {
    data = ([ ]);
}
