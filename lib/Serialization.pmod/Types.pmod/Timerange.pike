inherit Serialization.Types.Base;
inherit Serialization.BasicTypes;
inherit Serialization.PsycTypes;
inherit Serialization.Signature;

object list;

void create(object typecache) {
    Serialization.Types.Base::create("_timerange");
    Serialization.Signature::create(typecache);
 
    list = List(Int());
}

int decode(Serialization.Atom a) {
    array(int) l = list(a);

    if (sizeof(l) & 1) {
	werror("decoded timerange with odd times.\n");
	// *g

	throw(({}));
    }

    if (sizeof(l) > 2) {
	array(object) list = allocate(sizeof(l)/2);
	for (int i = 0; i < sizeof(list); i++) {
	    list[i] = Calendar.TimeRange("unix", l[2*i], l[2*i+1]);
	}

	return Calendar.SuperTimeRange(list);
    } else {
	return Calendar.TimeRange("unix", l[0], l[1]);
    }
}

Serialization.Atom encode(object timerange) {
    array(object) _l;

    if (timerange->is_supertimerange) {
	_l = timerange->parts;
    } else {
	_l = ({ timerange });
    }

    array(int) l = allocate(sizeof(_l)*2);

    foreach (int i = 0; i < sizeof(_l); i++) {
	l[2*i] = _l[i]->ux;
	l[2*i+1] = _l[i]->len;
    }

    return Serialization.Atom("_timerange", list->encode(l));
}

int(0..1) can_encode(mixed a) {
    return Program.inherits(object_program(a), Calendar.Time);
}

