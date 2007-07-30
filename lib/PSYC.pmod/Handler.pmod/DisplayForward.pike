#include <debug.h>
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


void create(object c, function s, MMP.Uniform uni, MMP.Uniform client_uni, object tdb) {
    to = client_uni;
    textdb = tdb;
    ::create(c, s, uni);
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

	if (sr == parent->link_to) {
	    PSYC.Packet echo = PSYC.Packet("_echo_context_enter");
	    mixed group = m["_group"];

	    if (group && MMP.is_place(group)) {
		MMP.Packet pt = MMP.Packet(echo, ([ "_source_relay" : group ]));
		sendmmp(to, pt);
	    } else {
		P0(("PrimitiveClient", "Want to fake an _echo_context_enter but thats no context %O.\n", m["_group"]));
	    }

	    return PSYC.Handler.STOP;
	}
    }

    return PSYC.Handler.GOON;
}

int display(MMP.Packet p, mapping _v, mapping _m) {
    P2(("PrimitiveClient", "Forwarding %O to primitive client (%O).\n", p, to));

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
