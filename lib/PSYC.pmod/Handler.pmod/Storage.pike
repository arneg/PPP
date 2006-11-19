// vim:syntax=lpc
inherit PSYC.Handler.Base;

/* TODO: doesnt check if someone is allowed to store or retrieve data ,)
 * 	 information about linked clients should go with the misc mapping
 * 	
 * 	 replace p["_source"] by p->source() ???
 */

PSYC.Storage storage;

constant _ = ([ 
    "postfilter" : ([ 
	"_request_store" : 0,
	"_request_store_lock" : 0,
	"_request_store_unlock" : 0,
	"_request_retrieve" : 0,
	"_request_retrieve_lock" : 0,
	"_request_retrieve_unlock" : 0,
	"_request_lock" : 0,
	"_request_unlock" : 0,
    ]),
]);

int postfilter_request_store_lock(MMP.Packet p, mapping _v, mapping _m) {
    return _set(p, _v, _m, "_store_lock", storage->set_lock);
}

int postfilter_request_store_unlock(MMP.Packet p, mapping _v, mapping _m) {
    return _set(p, _v, _m, "_store_unlock", storage->set_unlock);
}

int postfilter_request_store(MMP.Packet p, mapping _v, mapping _m) {
    return _set(p, _v, _m, "_store", storage->set);
}

int _set(MMP.Packet p, mapping _v, mapping _m, string mc, function set) {
    PSYC.Packet m = p->data;

    if (!_m["itsme"]) {
	uni->sendmsg(p->source(), m->reply("_failure"+mc));
	return PSYC.Handler.STOP;
    }

    if (!has_index(m->vars, "_key") || !has_index(m->vars, "_value")) {
	uni->sendmsg(p["_source"], m->reply("_error"+mc, "Store what???"));
	return PSYC.Handler.STOP;
    }

    string key = m->vars["_key"];
    mixed value = m->vars["_value"];

    void callback(int i, MMP.Uniform target, PSYC.Packet m) {
	if (i) {
	    uni->sendmsg(target, m->reply("_notice"+mc, 0,
					  ([ "_key" : key ])));
	} else {
	    uni->sendmsg(target, m->reply("_error"+mc, 0,
					  ([ "_key" : key ])));
	}
    };

    set(key, value, callback, p["_source"], m);
    return PSYC.Handler.STOP;
}

int postfilter_request_retrieve_lock(MMP.Packet p, mapping _v, mapping _m) {
    return _get(p, _v, _m, "_retrieve_lock", storage->get_lock);
}

int postfilter_request_retrieve_unlock(MMP.Packet p, mapping _v, mapping _m) {
    return _get(p, _v, _m, "_retrieve_unlock", storage->get_unlock);
}

int postfilter_request_retrieve(MMP.Packet p, mapping _v, mapping _m) {
    return _get(p, _v, _m, "_retrieve", storage->get);
}

int _get(MMP.Packet p, mapping _v, mapping _m, string mc, function get) {
    PSYC.Packet m = p->data;
    
    if (!_m["itsme"]) {
	uni->sendmsg(p->source(), m->reply("_failure"+mc));
	return PSYC.Handler.STOP;
    }

    if (!has_index(m->vars, "_key")) {
	uni->sendmsg(p["_source"], m->reply("_error"+mc, "ReTrIEve whAt!!"));
	return PSYC.Handler.STOP;
    }

    string key = m->vars["_key"];

    void callback(string key, string value, MMP.Uniform target, 
		  PSYC.Packet m) {
	if (value != UNDEFINED) {
	    uni->sendmsg(target, m->reply("_notice"+mc, 0, 
					  ([ "_key" : key,
					     "_value" : value ])));
	} else {
	    uni->sendmsg(target, m->reply("_error"+mc, 0,
					  ([ "_key" : key ])));
	}
    };

    get(key, callback, p["_source"], m);
    return PSYC.Handler.STOP;
}

int postfilter_request_lock(MMP.Packet p, mapping _v, mapping _m) {
    PSYC.Packet m = p->data;

    if (!_m["itsme"]) {
	uni->sendmsg(p->source(), m->reply("_failure_lock"));
	return PSYC.Handler.STOP;
    }

    if (!has_index(m->vars, "_key")) {
	uni->sendmsg(p["_source"], m->reply("_error_lock", "Lock what??"));
	return PSYC.Handler.STOP;
    }

    string key = m->vars["_key"];

    void callback(int error, MMP.Uniform target, PSYC.Packet m) {
	if (error) {
	    uni->sendmsg(target, m->reply("_error_lock", 0,
					  ([ "_key" : key ])));
	} else {
	    uni->sendmsg(target, m->reply("_notice_lock", 0,
					  ([ "_key" : key ])));
	}
    };

    storage->lock(key, callback, p->source(), m);
    return PSYC.Handler.STOP;
}

int postfilter_request_unlock(MMP.Packet p, mapping _v, mapping _m) {
    PSYC.Packet m = p->data;

    if (!_m["itsme"]) {
	uni->sendmsg(p->source(), m->reply("_failure_unlock"));
	return PSYC.Handler.STOP;
    }

    if (!has_index(m->vars, "_key")) {
	uni->sendmsg(p["_source"], m->reply("_error_unlock", "Lock what??"));
	return PSYC.Handler.STOP;
    }

    string key = m->vars["_key"];

    void callback(int error, MMP.Uniform target, PSYC.Packet m) {
	if (error) {
	    uni->sendmsg(target, m->reply("_error_unlock", 0,
					  ([ "_key" : key ])));
	} else {
	    uni->sendmsg(target, m->reply("_notice_unlock", 0,
					  ([ "_key" : key ])));
	}
    };

    storage->unlock(key, callback, p->source(), m);
    return PSYC.Handler.STOP;
}

void create(object uni, object s) {
    storage = s;
    ::create(uni);
}

