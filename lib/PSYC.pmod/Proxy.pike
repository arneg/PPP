/*
Copyright (C) 2008-2009  Arne Goedeke
Copyright (C) 2008-2009  Matt Hardy

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
version 2 as published by the Free Software Foundation.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
*/
inherit PSYC.Base;

object session;
object mmp_signature;

mapping(MMP.Uniform:int) clients = ([]);

void create(object server, object uniform, object session) {
	::create(server, uniform);
	mmp_signature = Packet(Atom());
	session->cb = incoming;
	session->error_cb = session_error;
	this_program::session = session;
}

void session_error(object session, string err) {
    	// TODO: get rid of the proxy
	werror("ERROR: %O %s\n", session, err);
}

void incoming(object session, Serialization.Atom atom) {
	MMP.Packet p = mmp_signature->decode(atom);

	//werror("%s <<<<<<< \t%s %O\n", (string)uniform, p->data->type, p->vars);

	//werror("%s->incoming(%O, %O)\n", this, session, m);
	p->vars["_source"] = uniform;
	MMP.Uniform target = p->vars["_target"];

	// TODO: check for _request_retrieval and deliver if available
	server->msg(p);
}

int msg(MMP.Packet p) {

    	// TODO: implement the proxy functionality here
	//if (::msg(p) == PSYC.STOP) return PSYC.STOP;
	
	//werror("%s >>>>>>> \t%s %O\n", (string)uniform, p->data->type, p->vars);

	string|MMP.Utils.Cloak atom;

	mixed err = catch {
		if (has_index(p->vars, "_context")) {
			mmp_signature->encode(p);
		}

	    	atom = mmp_signature->render(p);
	};

	if (err) {
		werror("Failed to encode %O: %s\n", p, describe_error(err));
		return Yakity.STOP;
	}
	//werror("SENDING: %O\n", atom->get());

	session->send(atom); 
}
