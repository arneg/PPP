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
  sql = params->sql;
  ::create(params - ([ "sql":0, "sqlserver":0, "mailserver":0 ]));
}

constant _ = ([
    "postfilter" : ([
	"_request_log_email" : 0,
    ]),
//    "filter" : ([
//	"_notice_context_leave" : 0,
//    ]),
    "casted" : ([
	"_message" : 0,
    ]),
    "notify" : ([
	"member_left" : 0,
	"member_entered" : 0,
    ]),
]);

int postfilter_request_log_email(MMP.Packet p, mapping _v, mapping _m)
{
  PSYC.Packet m = p->data;

  if(MMP.is_uniform(p->lsource()))
  {
    array log = ({});

    if (mappingp(parent->history))
    foreach(reverse(parent->history);; MMP.Packet m)
    {
      if (has_prefix(m->data->mc,"_notice_context_enter") && m->lsource() == p->lsource() )
        break;
      if (has_prefix(m->data->mc,"_message"))
      {
	log += ({ sprintf("%s says: %s", m->lsource()->resource[1..], m->data->data) });
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

int prefilter_message_public(MMP.Packet p, mapping _v, mapping _m) 
{
  P0(("Place", "[%s]HISTORY: %O\n", Calendar.now()->format_time_xshort(), p));
  return PSYC.Handler.GOON;
}

int casted_message(MMP.Packet p, mapping _v) 
{
  debug("Place", 2, "[%s]sql_log: %O\n", Calendar.now()->format_time_xshort(), p);
  if (!sql && sqlserver)
      sql = Sql.Sql(sqlserver);

  if (sql)
  {
    sql->query("INSERT INTO chat_log (session_id, sender, recipient, message) VALUES(:session_id, :sender, :recipient, :message)",
             ([
                "session_id":(sessions[uni->resource]?sessions[uni->resource]->id:0),
                ":sender"   :(p->lsource()?p->lsource()->resource:0),
                ":recipient":uni->resource,
                ":message"  :p->data->data,
             ])
            );
  }

  return PSYC.Handler.GOON;
}

void notify_member_entered(MMP.Uniform guy) 
{
  debug("Place", 0, "ENTER: %O(%O) => %O(%O)\n", guy->resource, guy, uni->resource, uni);
  if (!sql && sqlserver)
      sql = Sql.Sql(sqlserver);

    if (!sessions[uni->resource])
      sessions[uni->resource] = ([]);

    if (sql)
    {
      sql->query("INSERT INTO chat_sessions (session_id, name, room, begin) VALUES(:session_id, :name, :room, NOW())",
	       ([
		   ":session_id" : sessions[uni->resource]->id,
		   ":name"       : guy->resource,
		   ":room"       : uni->resource,
	       ])
	      );
      if (!sessions[uni->resource]->id)
      {
	sessions[uni->resource]->id=sql->master_sql->insert_id();
	sql->query("UPDATE chat_sessions SET session_id=:session_id WHERE id=:session_id AND name=:name AND room=:room",
		 ([
		     ":session_id" : sessions[uni->resource]->id,
		     ":name"       : guy->resource,
		     ":room"       : uni->resource,
		 ]),
		);
      }
    }

    sessions[uni->resource][guy->resource]++;
}

void notify_member_left(MMP.Uniform guy) 
{
  debug("Place", 0, "LEAVE: %O(%O): %O(%O) =>\n", guy->resource, guy, uni->resource, uni);
  if (!sql && sqlserver)
      sql = Sql.Sql(sqlserver);

  if (sql)
  {
    sql->query("UPDATE chat_sessions SET end=NOW() WHERE session_id=:session_id AND name=:name AND room=:room",
               ([
                  ":session_id" : (sessions[uni->resource]?sessions[uni->resource]->id:0),
                  ":name"       : guy->resource,
                  ":room"       : uni->resource,
               ])
              );
  }

  if (sessions[uni->resource])
  {
    m_delete(sessions[uni->resource], guy->resource);

    if (sizeof(sessions[uni->resource]) == 1 && sessions[uni->resource]->id)
	m_delete(sessions, uni->resource);
  }
}
