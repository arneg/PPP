#include <debug.h>
inherit PSYC.Handler.Base;

//! This handler provides special helpdesk functions

string sqlserver;
object sql;
mapping channels = ([]);

void create(object o, function fun, MMP.Uniform uniform, string _sqlserver)
{
  sqlserver = _sqlserver;
  ::create(o, fun, uniform);
}


constant _ = ([
    "postfilter" : ([
//	"_request_members" : 0,
    ]),
    "prefilter" : ([
	"_request_context_enter" : 0,
    ]),
]);

int prefilter_request_context_enter(MMP.Packet p, mapping _v, mapping _m)
{
  if (parent->qName() && p->data["_supplicant"])
  {
    ;
  }

  return PSYC.Handler.GOON;
}

int postfilter_request_members(MMP.Packet p, mapping _v, mapping _m)
{
  PSYC.Packet m = p->data;
  P0(("Helpdesk", sprintf("[%s]HELPDESK: _request_members\n", Calendar.now()->format_time_xshort())));


  if(MMP.is_uniform(p->lsource()))
  {
    sendmsg(p->lsource(), m->reply("_notice_context_members", 
                                   (["_group":parent->qName(),
				     "_list_members":(array)(parent->context->members||(<>)),
                                   ])));
    return PSYC.Handler.STOP;
  }
  return PSYC.Handler.GOON;
}
