

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
   
    string uni;
    mapping user = ([ ]);

    create(string s) {
	uni = s;
    }

    int msg(Psyc.psyc_p m) {
	
	switch (m->mc) {
	    
	}

	if (::msg(m))
	    return 1;

	
    }

}
