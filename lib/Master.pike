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

inherit PSYC.Uni : unii;
inherit Group : group;

int counter = 0;
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

    _true();

    member[p->lsource] = ts;

    if (!has_index(routes, ts)) {
	routes[ts] = (< p->lsource >);
    } else {
	routes[ts][p->lsource] = 1;
    }
}

int leave(MMP.Packet p) {
    MMP.Uniform ls = p->lsource;
    
    if (has_index(member, ls)) {
	MMP.Uniform r = member[ls];

	P0(("Master", "leaveing in %O\n", routes))
	if (sizeof(routes[r]) > 1 && has_index(routes[r], ls)) {
	    routes[r][ls] = 0;
	} else {
// this is the transparent _link and _unlink stuff we are not using right now
#if 0
	    sendmsg(r, PSYC.Packet("_notice_unlink", "Your dont have any users anymore, me friend!"));
#endif
	    m_delete(routes, r);
	}

	m_delete(member, ls);
	
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
	   sendmsg(s, PSYC.Packet("_error_unlink_illegal", "Kick out your Members first, you ignorant swine!"));
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
    // maybe this is a bad idea.. we only need that for _request link
    if (!has_index(p->vars, "_source_relay") && group::msg(p)) return 1;

    PSYC.Packet m = p->data;

    switch(m->mc) {
    case "_request_enter":
	{
	    void _true() {
		sendmmp(p["_source"], MMP.Packet(m->reply("_notice_enter", "[_nick] enters [_nick_place].", ([ "_nick" : p->lsource, "_nick_place" : uni ])), 
						 ([ 
				    "_target_relay" : p->lsource,
						]))); 
		kast(PSYC.Packet("_notice_enter", "[_nick] enters [_nick_place].", ([ "_nick" : p->lsource, "_nick_place" : uni ])), p->lsource);

	    };

	    void _false() {
		sendmmp(p["_source"], MMP.Packet(m->reply("_failure"), 
						 ([ 
				    "_target_relay" : p->lsource,
						]))); 

	    };

	    enter(p, _true, _false);
	    return 1;
	}
	break;
    case "_request_leave":
	if (leave(p)) {
	    sendmmp(p["_source"], MMP.Packet(m->reply("_echo_leave"), ([ "_target_relay" : p->lsource ])));
	    kast(PSYC.Packet("_notice_leave", "[_nick] leaves [_nick_place].", ([ "_nick" : p->lsource, "_nick_place" : uni ])), p->lsource);
	}

	return 1;
#if 0
    case "_request_link":
	{
	    void _true() {
		sendmsg(p["_source"], m->reply("_notice_link"));
	    };

	    void _false() {
		sendmsg(p["_source"], m->reply("_failure_link", "keep on tryin', buddy"));
	    };

	    link(p, _true, _false);

	    return 1;
	}
    case "_request_unlink":
	{
	    sendmsg(p["_source"], m->reply("_notice_unlink"));
	}
    case "_notice_unlink":
	// we can leave it like this!
	unlink(p);
	return 1;
#endif
    }
}

void castmsg(MMP.Packet p) {
    // does this clash??

    if (!has_index(p->vars, "_counter")) {
	p["_counter"] = counter++;
    }

    foreach (routes;MMP.Uniform uniform;) {
	server->deliver(uniform, p);
    }
}

void kast(PSYC.Packet m, void|MMP.Uniform source_relay) {
    MMP.Packet p = MMP.Packet(m, ([ "_context" : uni ]));
    if (source_relay) p["_source_relay"] = source_relay;

    castmsg(p);
}
