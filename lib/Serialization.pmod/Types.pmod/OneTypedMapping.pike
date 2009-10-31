inherit .Mapping;
object ktype, vtype;

void create(object ktype, object vtype) {
    ::create("_mapping");
    
    this_program::ktype = ktype;
    this_program::vtype = vtype;
}

object get_ktype(mixed key) { return ktype; }
object get_vtype(mixed key, object ktype, mixed val) { return vtype; }

// its probably a good idea to decode right away. its pretty unlikely that we
// will just check and not use the data often.
int(0..1) can_decode(Serialization.Atom a) {
    if (mixed err = catch { decode(a); }) {
		return 0;
    }

    return 1;
}

int(0..1) can_encode(mixed a) {
    if (low_can_decode(a)) return 1;
    if (!mappingp(a)) return 0;

    foreach (a; mixed key; mixed val) {
		if (!ktype->can_encode(key)) return 0;
		if (!vtype->can_encode(val)) return 0;
    }

    return 1;
}

string _sprintf(int c) {
    if (c == 'O') {
	return sprintf("Mapping(%O : %O)", ktype, vtype);
    }

    return 0;
}
