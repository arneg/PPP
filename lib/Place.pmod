#include <debug.h>

// discussion: was hältst du eigentlich davon, wenn places auch mehrere 
// "clients" haben. das könnte dann sowohl nen webexport als auch nen 
// psyc-slave sein. oder nen irc-gateway 
//
// die frage ist im wesentlichen, ob das konzeptionell was vollkommen anderes
// ist als im User oder eher nicht. .. 

class Basic {
    inherit Master;

    void create(mixed ... bla) {
	P2(("Place.Basic", "create\n"))
	
	::create(@bla);
    }
    
    int msg(MMP.Packet p) {
	if (::msg(p)) return 1;
	P2(("Place.Basic", "%O->msg(%O)\n", this, p))
	
	PSYC.Packet m = p->data;
	// mcs allowed without being a groupie
	switch (m->mc) {
	
	}

	if (!isMember(p->lsource)) {
	    sendmsg(p["_source"], PSYC.Packet("_error_membership_required", 
		    "You need to enter the group first."));
	}

	switch(m->mc) {
	case "_message":
	case "_message_public":
	    {
		PSYC.Packet cm = copy_value(m);
		// this->castmsg() because we want to call the castmsg() of the
		// inheriting class(es)
		//
		// TODO: check for nicks..
		m["_nick"] = p->lsource;

		kast(m, p->lsource);
		return 1;
	    }
	}
	
	return 0;
    }

}
