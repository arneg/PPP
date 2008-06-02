inherit .Base;
object type;

void create(object type) {
    ::create("_list");
    
    this_program::type = type;
}

array decode(Serialization.Atom a) {
    if (!can_decode(a)) throw(({}));

    object parser = Serialization.AtomParser();

    parser->feed(a->data);
    array list = parser->parse_all();

    foreach (list;int i;Serialization.Atom item) {
	list[i] = type->decode(item);
    }

    return list;
}

Serialization.Atom encode(array a) {
    String.Buffer buf = String.Buffer();
    
    // we want late rendering...!!!
    foreach (a;; mixed t) {
	Serialization.render_atom(type->encode(t), buf);
    }

    return Serialization.Atom("_list", (string)buf);
}

int(0..1) can_encode(mixed a) {
    return arrayp(a);
}
