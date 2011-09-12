inherit .Base;

void create(string type) {
    ::create(type||"_binary");
}

int(0..1) can_encode(mixed a) {
    return stringp(a);
}

string decode(Serialization.Atom a) {
	return a->data;
}

Serialization.Atom encode(string s) {
    return Serialization.Atom(type, s);
}

Serialization.StringBuilder render(string method, Serialization.StringBuilder buf) {
    buf->add(sprintf("%s %d %s", type, (sizeof(method)), method));
    return buf;
}

string _sprintf(int type) {
    if (type == 'O') {
	return sprintf("Serialization.Binary(%s)", this_program::type);
    }

    return 0;
}
