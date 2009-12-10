inherit .Base;

object get_ktype(mixed key);
object get_vtype(mixed key, object ktype, mixed value);
int(0..1) can_encode(mixed m);

void done_to_medium(Serialization.Atom atom) {
    array a;
	mapping done = atom->typed_data[this];

	a = allocate(sizeof(done)*2);
	int i = 0;

    foreach (done; mixed key; mixed value) {
		object ktype = get_ktype(key);
		if (!ktype) error("something totally unexpected happened during render. seems like %O has been changed since encode()\n", done);
		object vtype = get_vtype(key, ktype, value);
		if (!vtype) error("something totally unexpected happened during render. seems like %O has been changed since encode()\n", done);
		Serialization.Atom mkey = ktype->encode(key);
		Serialization.Atom mval = vtype->encode(value);
		a[i++] = mkey;
		a[i++] = mval;
    }

    atom->set_pdata(a);
}

void medium_to_done(Serialization.Atom atom) {
    mapping done = ([]);

	for (int i = 0; i < sizeof(atom->pdata); i+=2) {
		Serialization.Atom mval, mkey = atom->pdata[i];
		object ktype = get_ktype(mkey);
		if (!ktype) error("something totally unexpected happened during render. seems like %O has been changed since encode()\n", done);
		mval = atom->pdata[i+1];
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
    if (sizeof(list) & 1) return 0;

    // we keep the array.. more convenient
    atom->set_pdata(list);
}

void medium_to_raw(Serialization.Atom atom) {
    String.Buffer buf = String.Buffer();

	for (int i = 0; i < sizeof(atom->pdata); i+=2) {
		buf = atom->pdata[i]->render(buf);
		buf = atom->pdata[i+1]->render(buf);
	}

    atom->data = (string)buf;
}

int(0..1) can_encode(mixed a) {
    return mappingp(a);
}
