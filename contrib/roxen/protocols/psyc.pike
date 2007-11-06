// This is a roxen protokol module. 
// (c) 2007 Arne Goedeke, Martin Bähr, Tobias S. Josefowitz, Webhaven
//
// psyc.pike
// Roxen PSYC Protocol
// glue for the PSYC protocol.

constant cvs_version="$Id: psyc.pike,v 0.1 mbaehr Exp $";

#define DEBUG 0

constant version = "1.0";

object my_fd; // The file descriptor
object port_obj; // The port object
object conf;  // The current configuration

mapping (string:mixed)  misc = ([ ]);
string localhost; // Name of the psyc server.
string localaddr; // IP address
int localport;

object pipe; // The pipe...
object r_lock;

string remoteaddr; // Remote IP address.
string remotehost; // Remote host name.
string ident;

void create(object f, object c, object cc) 
{
  if(f) 
  {
    my_fd=f;
    if( c ) port_obj = c;
    if( cc ) conf = cc;
    //dns=Protocols.DNS.client();
    array tmp;

    catch(remoteaddr=((my_fd->query_address()||"")/" ")[0]);

    localhost = gethostname();
    if (localhost && arrayp(tmp = gethostbyname(localhost)))
    {
	localaddr = tmp[1][0];
    }
    else 
    {
	localaddr = localhost = port_obj->ip;
    }

    remotehost = roxen->blocking_ip_to_host(remoteaddr);
    create_server();
    werror("Psychaven %s:%O\n", localhost, port_obj->servers);

    int connectedport = array_sscanf(f->query_address(1), "%{%d.%d.%d.%d%} %d")[1];
    if ( connectedport < 1024 )
    {
      object policy = MMP.Utils.CrossDomainPolicy(localaddr, connectedport);
      policy->allow_port_range(localhost, connectedport);
      object flashfile = MMP.Utils.FlashFile(policy);
      flashfile->assign(f);
      f = flashfile;
    }
      
    port_obj->servers[conf]->add_socket(f);
  }
}


string text_db_path = "../psyced/world/default/";
// string text_db_path = "../default/";
string data_path = "/usr/local/roxen/local/psyc_data/";
string bind;


void create_server()
{
  werror("Psychaven create_server() %s:%O\n", localhost, port_obj->servers);
  if (!port_obj->servers[conf])
  {
    
    function textdb = PSYC.Text.FileTextDBFactoryFactory(text_db_path);

    PSYC.Storage.Factory storage = PSYC.Storage.FileFactory(data_path); 
    object debug = MMP.Utils.DebugManager();
    debug->set_default_backtrace(-1); // throws only.
    debug->set_default_debug(1);
    debug->set_debug("Handler.History", 10);
    debug->set_debug("packet_flow", 1);
    debug->set_debug("Email", 5);
    debug->set_debug("channel_membership", 5);

    mapping config = ([
             "debug" : debug,
           "bind_to" : localaddr,
	   "storage" : storage,
      "create_local" : create_local,
     "offer_modules" : ({ "_compress" }),
    "deliver_remote" : deliver_remote,
    "module_factory" : create_module,
 "default_localhost" : localhost,
            "textdb" : textdb,
    "stille_duldung" : 1,
         "love_json" : 1,
  "primitive_client" : 1,
                     ]);

    if (localaddr && localaddr != localhost)
        config->localhosts = ({ localaddr });

    PSYC.Server root = PSYC.Server(config);
    port_obj->servers[conf] = root;

    werror("Psychaven %s ready: %s\n", localhost, Calendar.ISO.now()->format_smtp());
    return;
  }
}

void deliver_remote(MMP.Packet p, MMP.Uniform target) {
    
    switch (target->scheme) { 
    case "psyc":
	port_obj->servers[conf]->deliver_remote(p, target);	
	break;
    }
}

// does _not_ check whether the uni->host is local.
object create_local(mapping params) 
{
    werror("create_local(%O)\n", params);
    MMP.Uniform uni = params["uniform"];
    params += ([ "storage" : params["storage_factory"]->getStorage(uni),
		     ]);
    write("creating object for %O.\n", uni);
    object o;
    if (uni->resource && sizeof(uni->resource) > 1) 
    {
      switch (uni->resource[0]) 
      {
        case '~':
	{
          // TODO check for the path...
          o = PSYC.Person(params);
	}
        break;
        case '@':
	{
          o = PSYC.Place(params);
	}
        break;
      } 
      mapping handler_params = params + ([ "parent" : o,
		                               "sendmmp" : o->sendmmp,
                                        ]);
      array handlers = conf->call_provider("psyc", "get_handlers", uni->resource[0], handler_params);
      werror("create_local() - handlers:%O\n", handlers);
      if(handlers)
        o->add_handlers(@handlers);
    }
    else 
      o = PSYC.Root(params);

//    o->add_handlers( 
//	  PSYC.Handler.ClientFriendship(o, o->sendmmp, uni),
//	           );

    return o;
}

// we transmit the variables of the neg packet. i dont have a better idea
// right now
object create_module(string name, mapping vars) {

    switch (name) {
    case "_compress":
	
    case "_encrypt":

    }
}
