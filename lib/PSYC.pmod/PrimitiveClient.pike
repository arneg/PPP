// vim:syntax=lpc
//
#include <debug.h>
#include <new_assert.h>

object client;
MMP.Uniform client_uniform;
object textdb;

inherit PSYC.CommandSingleplexer;
inherit MMP.Utils.Debug;

void create(mapping params) {
    // das wird wieder boese hier, 

    ::create(params["debug"]);

    enforce(MMP.is_uniform(client_uniform = params["client_uniform"]));

    void error() {
	P0(("PrimitiveClient", "error() called... \n"))
	client->client_sendmsg(client_uniform, PSYC.Packet("_error_link"));
    };

    // TODO: do something more useful in here (as soon as dumbclient-clients get spawned by a service)
    void query_password() {
	P0(("PrimitiveClient", "query_password() called... \n"))
	client->client_sendmsg(client_uniform, PSYC.Packet("_query_password"));
    };

    enforce(params["server"]);
    textdb = params["server"]->textdb_factory("plain", "en");

    // still not that beautyful.. the client doesnt need to do linking
    // in this case. doesnt matter

    mapping client_params = params + ([ "query_password" : query_password,
				        "error" : error ]);

    client = PSYC.Client(client_params);

    client->attach(this);
    client->uni->handler = client;

    mapping handler_params = params + ([
	"sendmmp" : client->client_sendmmp,
	"parent" : client,
	"uniform" : client->uni,
    ]);

    client->add_handlers(
	PSYC.Handler.Execute(handler_params),
	PSYC.Handler.PrimitiveLink(handler_params),
	// person uniform here to enter the uni.
	PSYC.Handler.Subscribe(handler_params),
	PSYC.Handler.DisplayForward(params),
	PSYC.Handler.ClientFriendship(handler_params),
	PSYC.Handler.Do(handler_params),
    );

    add_commands(
	PSYC.Commands.Tell(handler_params),
	PSYC.Commands.Enter(handler_params),
	PSYC.Commands.Set(handler_params),
    );
}
