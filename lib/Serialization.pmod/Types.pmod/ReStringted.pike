inherit .String;

object checker;

void create(string re, void|int options) {
    checker = Regexp.PCRE(re, options);
}

int(0..1) can_encode(mixed a) {
    return ::can_encode(a) && checker->match(a);
}

int(0..1) can_decode(Serialization.Atom atom) {
    return ::can_decode(atom) && checker->match(utf8_to_string(atom->data));
}
