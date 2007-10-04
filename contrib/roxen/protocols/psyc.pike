// This is a roxen module. 
// (c) 2007      Webhaven.
//
// psyc.pike
// Roxen PSYC Protocol
// glue for the PSYC protocol.
//
//  This code is (c) 2007 Webhaven.
//  it can be used, modified and redistributed freely
//  under the terms of the GNU General Public License, version 2.
//
//  This code comes on a AS-IS basis, with NO WARRANTY OF ANY KIND, either
//  implicit or explicit. Use at your own risk.
//  You can modify this code as you wish, but in this case please
//  - state that you changed the code in the modified version
//  - do not remove our name from it
//  - if possible, send us a copy of the modified version or a patch, so that
//    we can include it in the 'official' release.
//  If you find this code useful, please e-mail us. It would definitely
//  boost our ego :)
//
//  For risks and side-effects please read the code or ask your local
//  unix or roxen-guru.

constant cvs_version="$Id: psyc.pike,v 0.1 mbaehr Exp $";

#define DEBUG 0

constant version = "1.0";

object my_fd; // The file descriptor
object port_obj; // The port object
object conf;  // The current configuration

mapping (string:mixed)  misc = ([ ]);
string localhost; // Name of the mail server.
string localaddr; // IP address
int localport;

object pipe; // The pipe...
object r_lock;

string remoteaddr; // Remote IP address.
string remotehost; // Remote host name.
string ident;

void disconnect() {
  my_fd = 0;
  destruct();
}

void send(string what, array(int)|int|void code, int|void host);

void end(string|void s, array(int)|int|void code) {
  if(objectp(my_fd)) {
    catch {
      my_fd->set_close_callback(0);
      my_fd->set_read_callback(0);
      my_fd->set_blocking();
      send(s, code);
      my_fd->close();
      destruct(my_fd);
    };
    my_fd = 0;
  }
  disconnect();  
}


mixed handle_psyc(mixed cmd, mixed args) 
{
  mixed out;
  out = this_object()->conf->call_provider("psyc","handle_psyc",this_object(),cmd,args);
  //werror("PSYC: %O, %O, %O, %O\n", cmd, args, out, this_object()->conf->get_providers("psyc"));
  return out;
}

mixed log_psyc(mixed cmd, mixed args, mixed out, array(int)|int|void error, int|void size) 
{
  //werror("PSYC: %O, %O, %O, %O, %O, %O\n", cmd, args, out, error, size, this_object()->conf->get_providers("psyc_logger"));
  return this_object()->conf->call_provider("psyc_logger","log_psyc",this_object(),cmd, args, out, error, size||0);
}


// Some data arrived on the socket...
void got_data(mixed _id, string data);

void create(object f, object c, object cc) {

  if(f) {
    my_fd=f;
    if( c ) port_obj = c;
    if( cc ) conf = cc;
    dns=Protocols.DNS.client();
    array tmp;


    catch(remoteaddr=((my_fd->query_address()||"")/" ")[0]);
    catch(localaddr=((my_fd->query_address(1)||"")/" ")[0]);
    catch(localport=(int)((my_fd->query_address(1)||"")/" ")[1]);
    if(!remoteaddr) {
      end("No remote address?! Closing down.", ({421,4,3,2}));
      return;
    }
    if(!localaddr) {
      end("No local address?! Closing down.", ({421,4,3,2}));
      return;
    }
  //  tmp= dns->gethostbyaddr(localaddr);

    localhost=gethostname();
    remotehost = roxen->blocking_ip_to_host(remoteaddr);
    mark_fd(my_fd->query_fd(), "PSYC connection");
    my_fd->set_close_callback(end);
    my_fd->set_read_callback(got_data);
  }
}

