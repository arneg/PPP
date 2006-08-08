//vim:syntax=lpc
/*
 * grundform:
 * - master kennt alle user und entscheidet ueber join
 * - master kennt alls slaves/junctions/cslaves und entscheidet ueber links
 * - master vertraut mit gleichem host und fragt sonst (_trustiness)
 * - _source_relay ist eine list.. d.h. master fragt beim join nur den "ersten"
 *   junction in der kette, den er linken lassen hat
 */

#include "debug.h"

inherit Uni : unii;
inherit Group : group;

mapping(MMP.Uniform:multiset(MMP.Uniform)|int) routes = ([]);
mapping(MMP.Uniform:MMP.Uniform) member = ([]);

int isMember(MMP.Uniform typ) {
    return has_index(member, typ); 
}

// slaves und direkte user trennnen, alles andere ist bloedsinn
// fraglich, ob der enter dann ueberhaupt notwendig ist.. oder wir
// das nicht einfach direkt woanders erledigen.. mal sehen
// vielelichtr bessser doch nicht
//
// ahhh
//
void enter(MMP.Packet p, function _true, function _false) {
    P2(("Master", "Enter by %O, member: %O\n", p, member))
    MMP.Uniform ts = p["_source"];
    // the slave never linked

    if (has_index(p, "_source_relay") && !has_index(routes, ts)) {
	_false();

	return;
    }

    _true();

    member[p->lsource] = ts;

    if (multisetp(routes[ts])) {
	routes[ts][p->lsource] = 1;
    } else {
	routes[ts] = 1;
    }
}

int leave(MMP.Packet p) {
    MMP.Uniform ls = p->lsource;
    
    if (has_index(member, ls)) {
	MMP.Uniform r = member[ls];

	if (multisetp(routes[r])) {
	    if (!sizeof(routes[r])) {
		sendmsg(r, "_notice_unlink", "Your dont have any users anymore, me friend!");
		m_delete(routes, r);
	    }

	    routes[r][ls] = 0;
	} else {
	    m_delete(routes, r);
	}
	
	return 1;
    }

    return 0;
}

void link(MMP.Packet p, function _true, function _false) {
    routes[p["_source"]] = (< >);
    _true();
}

int unlink(MMP.Packet p) {
    MMP.Uniform s = p["_source"];

    if (has_index(routes, s)) {
       if (multisetp(routes[s]) && sizeof(routes[s])) {
	   sendmsg(s, "_error_unlink_illegal", "Kick out your Members first, you ignorant swine!");
	   multiset temp = m_delete(routes, s);
	   foreach (temp; MMP.Uniform uniform;) {
	       m_delete(member, uniform);
	       kast(PSYC.Packet("_notice_leave"), uniform);
	   }

	   return 0;
       }
       m_delete(routes, s);

       return 1;
    }

    return 0;
}

int msg(MMP.Packet p) {
    P2(("Place.Master", "%O->msg(%O)\n", this, p))

    if (unii::msg(p)) return 1;
    if (!has_index(p, "_source_relay") && group::msg(p)) return 1;

    PSYC.Packet m = p->data;

    switch(m->mc) {
    case "_request_enter":
	    // slave fragt, ob er leute joinen darf.. hier beantworten
	    //
    case "_request_link":
	{
	    void _true() {
		send(p["_source"], m->reply("_notice_link"));
	    };

	    void _false() {
		send(p["_source"], m->reply("_failure_link", "keep on tryin', buddy"));
	    };

	    link(p, _true, _false);

	    return 1;
	}
    case "_request_unlink":
	{
	    send(p["_source"], m->reply("_notice_unlink"));
	}
    case "_notice_unlink":
	// we can leave it like this!
	unlink(p);
	return 1;
    }
}

void castmsg(MMP.Packet p) {

    foreach (routes;MMP.Uniform uniform;) {
	server->deliver(uniform, p);
    }
}

void kast(PSYC.Packet m, void|MMP.Uniform source_relay) {
    MMP.Packet p = MMP.Packet(m, ([ "_context" : uni ]));
    if (source_relay) p["_source_relay"] = source_relay;

    castmsg(p);
}
