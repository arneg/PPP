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
	PSYC.Handler.PrimitiveLink(client, client->client_sendmmp, client->uni, 
				   client_uniform),
	// person uniform here to enter the uni.
	PSYC.Handler.Subscribe(client, client->client_sendmmp, person),
	PSYC.Handler.DisplayForward(client, client->client_sendmmp, client->uni, 
		       client_uniform),
	PSYC.Handler.ClientFriendship(client, client->client_sendmmp, 
				      client->uni),
	PSYC.Handler.Do(client, client->client_sendmmp, client->uni),
    );

//add_commands(PSYC.Commands.Subscribe(this));
    add_commands(
	PSYC.Commands.Tell(client, client->client_sendmmp, client->uni),
	PSYC.Commands.Enter(client, client->client_sendmmp, client->uni),
	PSYC.Commands.Set(client, client->client_sendmmp, client->uni),
    );
}

