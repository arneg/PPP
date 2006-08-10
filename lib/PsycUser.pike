#include <debug.h>

// could be the connection-object.
MMP.Uniform location;
object person;

void create(MMP.Uniform loc, object p) {
    location = loc;
    person = p;
}

// we need an itsme check.. somewhere
void msg(MMP.Packet p) { 

    PSYC.Packet m = p->data;

    switch (m->mc) {
    case "_request_store":
	{
	    string key;
	    foreach (indices(m->vars), key) {
		if (key[0] == '_' && MMP.is_mmpvar(key))
		    person->v[key] = m->vars[key];
	    }
	}
	break;
    case "_request_retrieve":
	{
	    string key;
	    mapping t = copy_value((mapping)(person->v));

	    // hmm. maybe we should store them in different mappings internally
	    // and .. hmm. we can do that for every storage type, can't we?
	    // we wont use plain mappings.. will we? ,)
	    //
	    //TODO: we should decide whether the library may corrupt vars or not
	    //.. maybe its worth allowing that.. maybe not.
	    //
	    // maybe pike even optimizes calls for copy_vars like:
	    // return sendmsg(bla, copy_value(vars));
	    // if the reference count of vars is 1.
	    foreach (indices(t), key) {
		if (key[0] != '_')
		    m_delete(t, key);
	    }
	    
	    person->sendmsg(p["_source"], "_status_storage", 0, t);
	}
	break;
    case "_request_execute":
	break;
    }
    
    person->send(location, m);
}

