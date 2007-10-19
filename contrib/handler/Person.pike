#include <debug.h>
inherit PSYC.Handler.Base;

//! This handler handles users
//!

constant _ = ([
    "prefilter" : ([
	"_request_do_enter" : 0,
	"_request_execute" : 0,
	"_request_do_exit" : 0,
    ]),
    "filter" : ([
	"_request_link" : ({ "password" }),
	"_echo_ping" : 0,
    ]),
    "postfilter" : ([
	"_request_do_invite" : 0,
	"_request_do_history" : 0,
	"_request_do_log_email" : 0,
    ]),
    "display" : ([
	"_notice_context_enter" : 0,
	"_notice_context_leave" : 0,
    ]),
]);

object sql;


int prefilter_request_execute(MMP.Packet p, mapping _v, mapping _m)
{
  P0(("Person", sprintf("[%s]PERSON: _request_execute\n", Calendar.now()->format_time_xshort())));
  return PSYC.Handler.GOON;
}

int display_notice_context_leave(MMP.Packet p, mapping _v, mapping _m)
{
    P0(("Person", sprintf("[%s]PERSON: _notice_context_leave\n", Calendar.now()->format_time_xshort())));
    return PSYC.Handler.GOON;
}

int display_notice_context_enter(MMP.Packet p, mapping _v, mapping _m)
{
  if(MMP.is_person(p->data["_supplicant"]) 
     && parent->qName() == p->data["_supplicant"] 
     && MMP.is_place(p->data["_group"]))
  {
    P0(("Person", sprintf("[%s]PERSON: _notice_context_enter\n", Calendar.now()->format_time_xshort())));
    sendmsg(p->data["_group"], PSYC.Packet("_request_members"));
  }
  if (p->vars->_context)
    return PSYC.Handler.GOON;
  return PSYC.Handler.STOP;
}

int prefilter_request_do_exit(MMP.Packet p, mapping _v, mapping _m)
{
  P0(("Person", sprintf("[%s]PERSON: _request_do_exit: %O:%O\n", Calendar.now()->format_time_xshort(), p->data, parent->clients)));
  return PSYC.Handler.GOON;
}

int prefilter_request_do_enter(MMP.Packet p, mapping _v, mapping _m)
{
  P0(("Person", sprintf("[%s]PERSON: _request_do_enter: %O\n", Calendar.now()->format_time_xshort(), p->data)));
  return PSYC.Handler.GOON;
}

int filter_request_link(MMP.Packet p, mapping _v, mapping _m)
{
  P0(("Person", sprintf("_request_link: %O\n", parent->clients)));
  if (sizeof(parent->clients) && !stringp(_v["password"]))
  {
    P0(("Person", "_error_nickname_used\n"));
    sendmsg(p["_source"], p->data->reply("_error_nickname_inuse"));
    return PSYC.Handler.STOP;
  }
  sendmsg(p["_source"], p->data->reply("_notice_ping"));
  return PSYC.Handler.GOON;
}

int filter_echo_ping(MMP.Packet p, mapping _v, mapping _m)
{
  P0(("Person", sprintf("_request_link: %O\n", parent->clients)));
  call_out(lambda(){ sendmsg(p["_source"], p->data->reply("_notice_ping")); }, 60);
  return PSYC.Handler.STOP;
}


int postfilter_request_do_history(MMP.Packet p, mapping _v, mapping _m)
{
  P0(("Person", sprintf("[%s]PERSON: _request_do_history: %O\n", Calendar.now()->format_time_xshort(), p->data)));
  sendmsg(p->data["_group"], PSYC.Packet("_request_history"));
  return PSYC.Handler.STOP;
}

int postfilter_request_do_invite(MMP.Packet p, mapping _v, mapping _m)
{
  P0(("Person", sprintf("[%s]PERSON: _request_do_invite: %O\n", Calendar.now()->format_time_xshort(), p->data)));
  sendmsg(p->data["_person"], PSYC.Packet("_notice_invitation", (["_place":p->data["_focus"] ]), p->data->data));
  return PSYC.Handler.STOP;
}

int postfilter_request_do_log_email(MMP.Packet p, mapping _v, mapping _m)
{
  P0(("Person", sprintf("[%s]PERSON: _request_do_log_email: %O\n", Calendar.now()->format_time_xshort(), p->data)));

  if(MMP.is_place(p->data["_group"]))
  {
/*
    send_tagged_v(room, 
     PSYC.Packet("_requet_history"), (< "_identification_scheme_mailto" 
	                >), callback);
*/
    sendmsg(p->data["_group"], PSYC.Packet("_request_log_email", (["_email_address":p->data["_email_address"]])));
  }
  return PSYC.Handler.STOP;
}
