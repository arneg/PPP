inherit MMP.Base : B;
inherit Serialization.Signature;
inherit PSYC.PsycTypes;

mapping(string:function) tags = ([]);
object ident;

string get_tag(function f) {
	string tag;

	while (has_index(tags, tag=random_string(4))) { }
	tags[tag] = f;

	return tag;
}

object message_signature;

void create(object server, MMP.Uniform uniform) {
    B::create(server, uniform);
    //S::create(server->type_cache);
	ident = MMP.Plugins.Identification(this);
    message_signature = Message(); // whatever
}

class Traverse(array(function|int) to_call, array args, void|function callback) {
	int pos = 0;
	int call_cb = 0;

	int result(int res) {
		if (res == PSYC.GOON) {
			if (pos + 1< sizeof(to_call)) {
				pos ++;
				return start();
			}
		}

		if (call_cb && callback) callback(res);

		return res;
	}

	int start() {
		int res;

		if (intp(to_call[pos])) res = to_call[pos];
		else res = to_call[pos](@args, result);

		if (res != PSYC.WAIT) return result(res);

		call_cb = 1;
		return PSYC.WAIT;
	}
}

int msg2(MMP.Packet p) {
	array(function) to_call = ({});

	if (has_index(p->vars, "_tag_reply")) {
		if (has_index(tags, p->vars->_tag_reply)) {
			to_call += ({ m_delete(tags, p->vars->_tag_reply) });
		}
	}

	if (message_signature->can_decode(p->data)) { // this is a psyc mc or something
		string method = p->data->type;

		if (method[0] == '_') {
			mixed f = this[method];
			
			if (functionp(f)) {
				to_call += ({ f });
			}

			array(string) t = method/"_";

			for (int i = sizeof(t)-2; i > 0; i--) {
				f = this[t[0..i]*"_"];
				if (functionp(f)) {
					to_call += ({ f });
				}
			}

			f = this->_;

			if (functionp(f)) {
				to_call += ({ f });
			}
		}
		if (sizeof(to_call)) return Traverse(to_call, ({ p, message_signature->decode(p->data) }))->start();
	} else if (sizeof(to_call)) return Traverse(to_call, ({ p, 0 }))->start();

}

int msg(MMP.Packet p, void|function cb) {
#ifdef DEBUG_MSG
    werror("%O->msg(%s, %O)\n", uniform, p->data->type, p->vars);
#endif
	if (cb) return Traverse(({ ::msg, ident->msg, msg2 }), ({ p }), cb)->start();
	else return Traverse(({ ::msg, ident->msg, msg2 }), ({ p }))->start();
}

void send(MMP.Uniform target, PSYC.Message|Serialization.Atom m, void|mapping vars, void|function callback) {
    if (callback) {
	vars = (vars||([]))+([ "_tag" : get_tag(callback) ]);
    }
    if (object_program(m) == PSYC.Message) {
	m = message_signature->encode(m);
    }
    ::send(target, m, vars);
}

void sendmsg(MMP.Uniform target, string method, void|string data, void|mapping m, void|function callback) {

	send(target, message_signature->encode(PSYC.Message(method, data, m)), 0, callback);
}

void sendreply(MMP.Packet p, PSYC.Message|Serialization.Atom m, void|mapping vars) {
    if (object_program(m) == PSYC.Message) {
	m = message_signature->encode(m);
    }
    ::sendreply(p, m, vars);
}

void sendreplymsg(MMP.Packet p, string method, void|string data, void|mapping m, void|function callback) {
	mapping vars = callback ? ([ "_tag" : get_tag(callback) ]) : 0;
	::sendreply(p, message_signature->encode(PSYC.Message(method, data, m)), vars);
}

int _request_retrieval(MMP.Packet p, PSYC.Message m, function callback) {
    array ids = m["_ids"];
    werror("%O: _request_retrieval(%d) of %O\n", p->source(), p["_id"], ids);

    object state = get_state(p->source());

    foreach (ids;;int i) {
		MMP.Packet packet = state->cache[i];
		werror("retransmission of %d\n", i);
		if (!packet) werror("Packet with id %d not available for retransmission\n", i);
		else server->msg(packet);
    }

    return PSYC.GOON;
}

int _message_public(MMP.Packet p, PSYC.Message m, function callback) {
   // werror("%O: _message_public(%d)\n", uniform, p["_id"]);
	return PSYC.GOON;
}
