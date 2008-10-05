#!/sw/bin/pike7.6

import PSYC;

constant ip = "127.0.0.13";

object ostorage;
object dumms;

object create_local(mapping params)
{
  MMP.Uniform uni = params["uniform"];
  params += ([ "storage" : params["storage_factory"]->getStorage(uni) ]);
  return PSYC.Root(params);
}

int main() 
{


  dumms = PSYC.Storage.FileFactory("data");

  ostorage = PSYC.Server((["default_localhost":ip,"create_local":create_local,"ports":({ip+":4404"}),"storage":dumms]));

  MMP.Uniform uni = ostorage->random_uniform("randomclient");
  werror("%O\n", uni);

  object debug = MMP.Utils.DebugManager();
  debug->set_default_backtrace(1);
  debug->set_default_debug(3);

  object psyc_client;

  mapping clientargs = (["person":ostorage->get_uniform("psyc://127.0.0.12/~username")
							, "uniform": uni
							, "server": ostorage
							, "error": dummyfunction
							, "query_password": dummyfunction
	       , "debug": debug]);

  psyc_client = PSYC.Client(clientargs);

  psyc_client->sendmmp(ostorage->get_uniform("psyc://127.0.0.12/~username2"), MMP.Packet(PSYC.Packet("_message_private", 0, "test")));


//  object pconnect;
//  pconnect = PSYC.Packet;

  return -1;
}


void dummyfunction(mixed ... args)
{
  write("%O", args);
}

class dummyclass
{}

