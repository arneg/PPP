#include <debug.h>

// discussion: was hältst du eigentlich davon, wenn places auch mehrere 
// "clients" haben. das könnte dann sowohl nen webexport als auch nen 
// psyc-slave sein. oder nen irc-gateway 
//
// die frage ist im wesentlichen, ob das konzeptionell was vollkommen anderes
// ist als im User oder eher nicht. .. 
// 	pro: die sache mit dem _request_link könnte universell sein.. fraglich 
// 	allerdings, ob man sich damit nicht eher einen abbricht..
//
// ausserdem: wollen wir eventuell den gruppen-krams in ein abstrakes modul
// packen, das wir nur inheriten?.. 

class Basic {

    inherit Group;
   
    mapping user = ([ ]);

    int msg(MMP.mmp_p p) {
	P2(("Place.Basic", "%O->msg(%O)\n", this, p))
	string|PSYC.uniform source = p["_source"];
	
	PSYC.psyc_p m = p->data;
	// mcs allowed without being a groupie
	switch (m->mc) {

	}

	if (psyc_msg(source, m)) return 1;

	if (!isMember(source)) {
	    sendmsg(source, "_error_membership_required", 
		    "You need to enter the group first.");
	}

	switch(m->mc) {
	case "_message":
	case "_message_public":
	    castmsg(m->mc, m->data, m->vars);
	    return 1;
	}
	
    }

}
