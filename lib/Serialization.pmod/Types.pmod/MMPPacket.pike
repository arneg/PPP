inherit .Struct;

void create(object dtype, object vtype) {
	::create("_mmppacket", MMP.Packet, dtype, vtype);
}

void done_to_medium(Serialization.Atom atom) {
	object p = atom->typed_data[this];

	if (!p) error("No typed data available.\n");

	atom->set_pdata(({ dtype->encode(p->data), vtype->encode(p->vars) }));
}

string _sprintf(int c) {
    if (c == 'O') {
		return sprintf("MMPPacket(%O, %O)", dtype, vtype);
    }

    return 0;
}
