#pike 7.6 
#include <debug.h>
inherit PSYC.Handler.Base;

//! This handler handles places

string sqlserver;
string mailserver;
object sql;
mapping sessions = ([]);

void create(mapping params)
{
  sqlserver = params->sqlserver;
  mailserver = params->mailserver;
  ::create(params - ([ "sqlserver":0, "mailserver":0 ]) );
}

constant _ = ([
    "postfilter" : ([
//	"_request_members" : 0,
//	"_request_history" : 0,
	"_request_log_email" : 0,
    ]),
    "filter" : ([
        "_notice_context_leave" : 0,
    ]),
    "prefilter" : ([
	"_request_context_enter" : 0,
	"_notice_context_leave" : 0,
//	"_message_public" : 0,
    ]),
    "display" : ([
	"_message" : 0,
    ]),
]);

int postfilter_request_history(MMP.Packet p, mapping _v, mapping _m)
{
  PSYC.Packet m = p->data;

  if(MMP.is_uniform(p->lsource()))
  {
    //sendmsg(p->lsource(), PSYC.Packet("_message_public", ([]), sprintf("welcome to %O\n", parent)));
    P0(("history", sprintf("%O\n", parent->history)));
    foreach(parent->history;; MMP.Packet m)
    {
      if(has_prefix(m->data->mc,"_message"))
      {
        P1(("Place", sprintf("%O\n", m->data->data)));
        MMP.Packet nm = m->clone();
	nm->vars->_target = p->lsource();
        nm->vars->_source_relay = m["_source"]||m["_source_relay"];
        sendmmp(p->lsource(), nm);
      }
    }
  }
  return PSYC.Handler.STOP;
}

int postfilter_request_log_email(MMP.Packet p, mapping _v, mapping _m)
{
  PSYC.Packet m = p->data;

  if(MMP.is_uniform(p->lsource()))
  {
    array log = ({});

    foreach(reverse(parent->history);; MMP.Packet m)
    {
      if (has_prefix(m->data->mc,"_notice_context_enter") && m->lsource() == p->lsource() )
        break;
      if (has_prefix(m->data->mc,"_message"))
      {
	log += ({ sprintf("%s says %s", m->lsource()->resource[1..], m->data->data) });
      }
    }
    string logtext = reverse(log)*"\n";
    P0(("Email", sprintf("%O\n%O\n", p->data["_email_address"], logtext)))
//    send_tagged(p->lsource(), 
//                PSYC.Packet("_request_retrieve", ([ "_key":"_identification_scheme_mailto" ])), 
//                lambda(MMP.Packet r, mixed ... args)
//                { 
//                  P0(("Email", sprintf("%O\n", r->data)))
                  Thread.Thread(lambda(){ Protocols.SMTP.Client(mailserver)->simple_mail(p->data["_email_address"], "Your Hyundai chatlog", "customerservice@hyundai.co.nz", logtext); });
//                });
  }
  return PSYC.Handler.STOP;
}

int postfilter_request_members(MMP.Packet p, mapping _v, mapping _m)
{
  PSYC.Packet m = p->data;
  P0(("Place", sprintf("[%s]PLACE: _request_members\n", Calendar.now()->format_time_xshort())));


  if(MMP.is_uniform(p->lsource()))
  {
    sendmsg(p->lsource(), m->reply("_notice_context_members", 
                                   (["_group":parent->qName()->resource,
				     "_list_members":(array)(parent->context->members||(<>)),
                                   ])));
    return PSYC.Handler.STOP;
  }
  return PSYC.Handler.GOON;
}

int prefilter_message_public(MMP.Packet p, mapping _v, mapping _m) 
{
  P0(("Place", sprintf("[%s]HISTORY: %O\n", Calendar.now()->format_time_xshort(), p)));
  return PSYC.Handler.GOON;
}

int display_message(MMP.Packet p, mapping _v, mapping _m) 
{
  if(!sql)
      sql = Sql.Sql(sqlserver);

  sql->query("INSERT INTO chat_log (session_id, sender, recipient, message) VALUES(:session_id, :sender, :recipient, :message)",
             ([
                "session_id":(sessions[parent->qName()->resource]?sessions[parent->qName()->resource]->id:0),
                ":sender"   :(p->lsource()?p->lsource()->resource:0),
                ":recipient":parent->qName()->resource,
                ":message"  :p->data->data,
             ])
            );
  return PSYC.Handler.GOON;
}

int prefilter_request_context_enter(MMP.Packet p, mapping _v, mapping _m) 
{
  if(!sql)
      sql = Sql.Sql(sqlserver);

  if (parent->qName() && p->data["_supplicant"])
  {
    P0(("Place", sprintf("ENTER: %O(%O) => %O(%O)\n", p->data["_supplicant"]->resource, p->data["_supplicant"], parent->qName()->resource, parent->qName())));
    if (!sessions[parent->qName()->resource])
      sessions[parent->qName()->resource] = ([]);

    sql->query("INSERT INTO chat_sessions (session_id, name, room, begin) VALUES(:session_id, :name, :room, NOW())",
	       ([
		   ":session_id" : sessions[parent->qName()->resource]->id,
		   ":name"       : p->data["_supplicant"]->resource,
		   ":room"       : parent->qName()->resource,
	       ])
	      );
    if (!sessions[parent->qName()->resource]->id)
    {
      sessions[parent->qName()->resource]->id=sql->master_sql->insert_id();
      sql->query("UPDATE chat_sessions SET session_id=:session_id WHERE id=:session_id AND name=:name AND room=:room",
	         ([
		     ":session_id" : sessions[parent->qName()->resource]->id,
		     ":name"       : p->data["_supplicant"]->resource,
		     ":room"       : parent->qName()->resource,
	         ]),
		);
    }

    sessions[parent->qName()->resource][p->data["_supplicant"]->resource]++;
  }
  return PSYC.Handler.GOON;
}

int filter_notice_context_leave(MMP.Packet p, mapping _v, mapping _m) 
{
  P0(("Place", sprintf("postLEAVE: %O(%O): %O(%O) => %O\n", p->data["_supplicant"]->resource, p->data["_supplicant"], parent->qName()->resource, parent->qName(), indices(parent) ))); //->context->members)));
#if 0
  // FIXME: this is a risky hack
  if (parent->context->members[p->data["_supplicant"]])
    parent->context->members = parent->context->members ^ (< p->data["_supplicant"] >);
#endif
  return PSYC.Handler.GOON;
}

int prefilter_notice_context_leave(MMP.Packet p, mapping _v, mapping _m) 
{
  if(!sql)
      sql = Sql.Sql(sqlserver);

  P0(("Place", sprintf("LEAVE: %O(%O): %O(%O) =>\n", p->data["_supplicant"]->resource, p->data["_supplicant"], parent->qName()->resource, parent->qName())));
  sql->query("UPDATE chat_sessions SET end=NOW() WHERE session_id=:session_id AND name=:name AND room=:room",
               ([
                  ":session_id" : (sessions[parent->qName()->resource]?sessions[parent->qName()->resource]->id:0),
                  ":name"       : p->data["_supplicant"]->resource,
                  ":room"       : parent->qName()->resource,
               ])
              );

  if (sessions[parent->qName()->resource])
  {
    m_delete(sessions[parent->qName()->resource], p->data["_supplicant"]->resource);

    if (sizeof(sessions[parent->qName()->resource]) == 1 
      && sessions[parent->qName()->resource]->id)
    m_delete(sessions, parent->qName()->resource);
  }
    
  return PSYC.Handler.GOON;
}
