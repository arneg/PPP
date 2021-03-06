#include <new_assert.h>
inherit PSYC.Handler.Base;

constant _ = ([
    "display" : ([
	"" : 0,
	"_notice_context_enter" : 0,
	"_message" : 0,
    ]),
]);

MMP.Uniform to;
object textdb;


void create(mapping params) {
    to = params["client_uni"];
    textdb = params["textdb"];

    ::create(params);

    enforce(MMP.is_uniform(to));
    enforce(objectp(textdb));
}

int display_message(MMP.Packet p, mapping _v, mapping _m) {
    MMP.Uniform source = p->lsource();


    if (MMP.is_person(source)) {
	p = p->clone();

	PSYC.Packet m = p->data->clone();
	p->data = m;

	m["_nick"] = source->resource[1..];

	forward(p);
	return PSYC.Handler.STOP;
    }

    return PSYC.Handler.GOON;
}

int display_notice_context_enter(MMP.Packet p, mapping _v, mapping _m) {
     PSYC.Packet m = p->data;

    if (has_index(p->vars, "_source_relay")) {
	MMP.Uniform sr = p["_source"];

	// not sure if this check is save. maybe not. can we send a msg through
	// the person containing a faked join?
	if (sr == parent->link_to && m["_supplicant"] == parent->link_to) {
	    PSYC.Packet echo = PSYC.Packet("_echo_context_enter");
	    mixed group = m["_group"];

	    if (group && MMP.is_place(group)) {
		MMP.Packet pt = MMP.Packet(echo, ([ "_source_relay" : group ]));
		sendmmp(to, pt);
	    } else {
		debug("protocol_error", 0, "_group in _notice_context_enter supposed to be a group. got: %O.\n", m["_group"]);
	    }

	    return PSYC.Handler.STOP;
	}
    }

    return PSYC.Handler.GOON;
}

int display(MMP.Packet p, mapping _v, mapping _m) {
    debug("PSYC.PrimitiveClient", 3, "Forwarding %O to primitive client (%O).\n", p, to);

    forward(p->clone());

    return PSYC.Handler.STOP;
}

void forward(MMP.Packet p) {
    p["_target"] = to;
    p["_source_relay"] = p->lsource();

    m_delete(p->vars, "_source");
    m_delete(p->vars, "_counter");

    if (PSYC.is_packet(p->data)) {
	PSYC.Packet m = p->data->clone();
	p->data = m;
	string tmp;

	// m->data should never be !stringp
	// could use enforce for that instead..
	if (!m->data || !sizeof(m->data)) {
	    tmp = textdb[m->mc];

	    if (tmp && sizeof(tmp)) 
		m->data = tmp;
	}
    }

    sendmmp(to, p);
}
