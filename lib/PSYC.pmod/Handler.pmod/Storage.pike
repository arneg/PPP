// vim:syntax=lpc
inherit PSYC.Handler.Base;

PSYC.Storage storage;

constant _ = ([ 
    "postfilter" : ([ 
	"_request_store" : 0,
	"_request_retrieve" : 0,
    ]),
]);

int postfilter_request_store(MMP.Packet p, mapping _v) {
    PSYC.Packet m = p->data;

    if (!has_index(m->vars, "_key") || !has_index(m->vars, "_value")) {
	uni->sendmsg(p["_source"], m->reply("_error_store", "Store what???"));
	return PSYC.Handler.STOP;
    }

    string key = m->vars["_key"];
    mixed value = m->vars["_value"];

    void callback(int i, MMP.Uniform target, PSYC.Packet m) {
	if (i) {
	    uni->sendmsg(target, m->reply("_notice_store"));
	} else {
	    uni->sendmsg(target, m->reply("_error_store"));
	}
    };

    storage->set(key, value, callback, p["_source"], m);
    return PSYC.Handler.STOP;
}

int postfilter_request_retrieve(MMP.Packet p, mapping _v) {
    PSYC.Packet m = p->data;

    if (!has_index(m->vars, "_key")) {
	uni->sendmsg(p["_source"], m->reply("_error_store", "ReTrIEve whAt!!"));
	return PSYC.Handler.STOP;
    }

    string key = m->vars["_key"];

    void callback(string key, string value, MMP.Uniform target, 
		  PSYC.Packet m) {
	if (value != UNDEFINED) {
	    uni->sendmsg(target, m->reply("_notice_retrieve", 0, 
					  ([ "_key" : key,
					     "_value" : value ])));
	} else {
	    uni->sendmsg(target, m->reply("_error_retrieve", 0,
					  ([ "_key" : key ])));
	}
    };

    storage->get(key, callback, p["_source"], m);
    return PSYC.Handler.STOP;
}

void create(object uni, object s) {
    storage = s;
    ::create(uni);
}

