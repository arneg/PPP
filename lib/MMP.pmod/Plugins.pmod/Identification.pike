inherit .Base;

int(0..1) authenticate(MMP.Uniform u);

mapping(MMP.Uniform:mapping(MMP.Uniform:int|array(function))) identifications = ([]);

int msg(MMP.Packet p, function callback) {
	if (!has_index(p->vars, "_source_identification")) return PSYC.GOON;

	MMP.Uniform source = p->vars->_source;
	MMP.Uniform id = p->vars->_source_identification;

	if (id == this->uniform) {
		if (authenticate(source)) {
			return PSYC.GOON;
		} else {
			return PSYC.STOP;
		}
	}

	if (!has_index(identifications, id)) {
		identifications[id] = ([]);
	}

	if (!has_index(identifications[id], source)) {
		int cb(MMP.Packet p, PSYC.Message m, function cb) {
			mixed a = identifications[id][source];
			if (!arrayp(a)) error("no packets waiting for authentication!\nhave: %O\n", a);
			if (m->method == "_notice_authentication") {
				werror("%O authenticated as %O\n", source, id);
				identifications[id][source] = 1;
				a(PSYC.GOON);
			} else {
				werror("%O did not auth as %O\n", source, id);
				identifications[id][source] = 0;
				a(PSYC.STOP);
			}

			return PSYC.STOP;
		};
		werror("%O: waiting for authentication of %O by %O\n", this->uniform, source, id);
		identifications[id][source] = ({ callback });
		sendmsg(id, "_request_authentication", 0, ([ "_supplicant" : source ]), cb);
		return PSYC.WAIT;
	} else if (arrayp(identifications[id][source])) {
		// waiting, so we append ours
		identifications[id][source] += ({ callback });
		return PSYC.WAIT;
	}

	if (identifications[id][source]) return PSYC.GOON;

	else {
		werror("%O is falsely identifying for %O\n", source, id);
		return PSYC.STOP;
	}
}
