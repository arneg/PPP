// vim:syntax=lpc
//
#include <debug.h>

object client;
MMP.Uniform client_uniform;
object textdb;

inherit PSYC.CommandSingleplexer;

void create(MMP.Uniform client_u, object server, MMP.Uniform person, string|void pw) {
    P0(("PrimitiveClient", "create(%O, %O, %O)\n", client_u, server, person))
    // das wird wieder boese hier, 
    client_uniform = client_u;

    void error() {
	P0(("PrimitiveClient", "error() called... \n"))
	client->client_sendmsg(client_uniform, PSYC.Packet("_error_link"));
    };

    // TODO: do something more useful in here (as soon as dumbclient-clients get spawned by a service)
    void query_password() {
	P0(("PrimitiveClient", "query_password() called... \n"))
	client->client_sendmsg(client_uniform, PSYC.Packet("_query_password"));
    };

    textdb = server->textdb_factory("plain", "en");

    // still not that beautyful.. the client doesnt need to do linking
    // in this case. doesnt matter
    MMP.Uniform t = server->random_uniform("primitive");
    client = PSYC.Client(person, server, t, error, query_password, pw);
    client->attach(this);
    t->handler = client;

    client->add_handlers(
	PSYC.Handler.Execute(client, client->client_sendmmp, client->uni),
	PSYC.Handler.PrimitiveLink(client, client->client_sendmmp, client->uni, client_uniform),
	// person uniform here to enter the uni.
	PSYC.Handler.Subscribe(client, client->client_sendmmp, person),
	DisplayForward(client, client->client_sendmmp, client->uni, client_uniform),
	PSYC.Handler.ClientFriendship(client, client->client_sendmmp, client->uni),
	PSYC.Handler.Do(client, client->client_sendmmp, client->uni),
    );

//add_commands(PSYC.Commands.Subscribe(this));
    add_commands(
	PSYC.Commands.Tell(client, client->client_sendmmp, client->uni),
	PSYC.Commands.Enter(client, client->client_sendmmp, client->uni),
	PSYC.Commands.Set(client, client->client_sendmmp, client->uni),
    );
}

class DisplayForward {
    constant _ = ([
	"display" : ([
	    "" : 0,
	    "_notice_context_enter" : 0,
	    "_message" : 0,
	]),
    ]);

    inherit PSYC.Handler.Base;

    MMP.Uniform to;


    void create(object c, function s, MMP.Uniform uni, MMP.Uniform client_uni) {
	to = client_uni;
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
		    P0(("PrimitiveClient", "Want to fake an _echo_context_enter but thats no context %O.\n", m["_group"]))
		}

		return PSYC.Handler.STOP;
	    }
	}

	return PSYC.Handler.GOON;
    }

    int display(MMP.Packet p, mapping _v, mapping _m) {
	PT(("PrimitiveClient", "Forwarding %O to primitive client (%O).\n", p, to))

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
}
