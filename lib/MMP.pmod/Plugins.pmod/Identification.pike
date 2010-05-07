object o;

void create(object o) {
	this_program::o = o;
}

mapping(MMP.Uniform:mapping(MMP.Uniform:int|array(function))) i = ([]);

int msg(MMP.Packet p, function callback) {
	if (!has_index(p->vars, "_source_identification")) return PSYC.GOON;

	MMP.Uniform source = p->vars->_source;
	MMP.Uniform id = p->vars->_source_identification;

	if (id == o->uniform) {
		if (o->authenticate(source)) {
			return PSYC.GOON;
		} else {
			return PSYC.STOP;
		}
	}

	if (!has_index(i, id)) {
		i[id] = ([]);
	}

	if (!has_index(i[id], source)) {
		int cb(MMP.Packet p, PSYC.Message m, function cb) {
			mixed a = i[id][source];
			if (!arrayp(a)) error("no packets waiting for authentication!");
			if (m->method == "_notice_authentication") {
				werror("%O authenticated as %O\n", source, id);
				i[id][source] = 1;
				a(PSYC.GOON);
			} else {
				werror("%O did not auth as %O\n", source, id);
				i[id][source] = 0;
				a(PSYC.STOP);
			}

			return PSYC.STOP;
		};
		o->sendmsg(id, "_request_authentication", 0, ([ "_supplicant" : source ]), cb);
		werror("%O: waiting for authentication of %O by %O\n", o->uniform, source, id);
		i[id][source] = ({ callback });
		return PSYC.WAIT;
	} else if (arrayp(i[id][source])) {
		// waiting, so we append ours
		i[id][source] += ({ callback });
		return PSYC.WAIT;
	}

	if (i[id][source]) return PSYC.GOON;
	else {
		werror("%O is falsely identifying for %O\n", source, id);
		return PSYC.STOP;
	}
}
