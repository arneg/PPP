inherit .Base;

object get_ktype(mixed key);
object get_vtype(mixed key, object ktype, mixed value);
int(0..1) can_encode(mixed m);

void done_to_medium(Serialization.Atom atom) {
    mapping m = ([]), done = atom->typed_data[this];

    foreach (done; mixed key; mixed value) {
		object ktype = get_ktype(key);
		if (!ktype) error("something totally unexpected happened during render. seems like %O has been changed since encode()\n", done);
		object vtype = get_vtype(key, ktype, value);
		if (!vtype) error("something totally unexpected happened during render. seems like %O has been changed since encode()\n", done);
		Serialization.Atom mkey = ktype->encode(key);
		Serialization.Atom mval = vtype->encode(value);
		m[mkey] = mval;
    }

    atom->set_pdata(m);
}

void medium_to_done(Serialization.Atom atom) {
    mapping done = ([]), m = atom->pdata;

    foreach (m;Serialization.Atom mkey;Serialization.Atom mval) {
		object ktype = get_ktype(mkey);
		if (!ktype) error("something totally unexpected happened during render. seems like %O has been changed since encode()\n", done);
		object vtype = get_vtype(mkey, ktype, mval);
		if (!vtype) error("something totally unexpected happened during render. seems like %O has been changed since encode()\n", done);

		mixed key = ktype->decode(mkey);
		mixed val = vtype->decode(mval);
		done[key] = val;
    }

    atom->set_typed_data(this, done);
}

void raw_to_medium(Serialization.Atom atom) {
    array(Serialization.Atom) list = Serialization.parse_atoms(atom->data);
    mapping m = ([]);

    if (sizeof(list) & 1) return 0;

    // we keep the array.. more convenient
    for (int i=0;i<sizeof(list);i+=2) {
		m[list[i]] = list[i+1];
    }

    atom->set_pdata(m);
}

void medium_to_raw(Serialization.Atom atom) {
    String.Buffer buf = String.Buffer();

	foreach (atom->pdata;Serialization.Atom key; Serialization.Atom value) {
		buf = key->render(buf);
		buf = value->render(buf);
	}

    atom->data = (string)buf;
}

int(0..1) low_can_encode(mixed a) {
    return mappingp(a);
}
