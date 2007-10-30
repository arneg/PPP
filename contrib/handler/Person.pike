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
  debug("Person", 0, sprintf("[%s]PERSON: _request_execute\n", Calendar.now()->format_time_xshort()));
  return PSYC.Handler.GOON;
}

int display_notice_context_leave(MMP.Packet p, mapping _v, mapping _m)
{
    debug("Person", 0, sprintf("[%s]PERSON: _notice_context_leave\n", Calendar.now()->format_time_xshort()));
    return PSYC.Handler.GOON;
}

int display_notice_context_enter(MMP.Packet p, mapping _v, mapping _m)
{
  if(MMP.is_person(p->data["_supplicant"]) 
     && parent->qName() == p->data["_supplicant"] 
     && MMP.is_place(p->data["_group"]))
  {
    debug("Person", 2, sprintf("[%s]PERSON: _notice_context_enter\n", Calendar.now()->format_time_xshort()));
    sendmsg(p->data["_group"], PSYC.Packet("_request_members"));
  }
  if (p->vars->_context)
    return PSYC.Handler.GOON;
  return PSYC.Handler.STOP;
}

int prefilter_request_do_exit(MMP.Packet p, mapping _v, mapping _m)
{
  debug("Person", 0, sprintf("[%s]PERSON: _request_do_exit: %O:%O\n", Calendar.now()->format_time_xshort(), p->data, parent->clients));
  return PSYC.Handler.GOON;
}

int prefilter_request_do_enter(MMP.Packet p, mapping _v, mapping _m)
{
  debug("Person", 0, sprintf("[%s]PERSON: _request_do_enter: %O\n", Calendar.now()->format_time_xshort(), p->data));
  return PSYC.Handler.GOON;
}

int filter_request_link(MMP.Packet p, mapping _v, mapping _m)
{
  debug("Person", 0, sprintf("_request_link: %O\n", parent->clients));
  if (sizeof(parent->clients) && !stringp(_v["password"]))
  {
    debug("Person", 0, "_error_nickname_used\n");
    sendmsg(p["_source"], p->data->reply("_error_nickname_inuse"));
    return PSYC.Handler.STOP;
  }
  sendmsg(p["_source"], p->data->reply("_notice_ping"));
  return PSYC.Handler.GOON;
}

int filter_echo_ping(MMP.Packet p, mapping _v, mapping _m)
{
  debug("Person", 0, sprintf("_request_link: %O\n", parent->clients));
  call_out(lambda(){ sendmsg(p["_source"], p->data->reply("_notice_ping")); }, 60);
  return PSYC.Handler.STOP;
}


int postfilter_request_do_history(MMP.Packet p, mapping _v, mapping _m)
{
  debug("Person", 0, sprintf("[%s]PERSON: _request_do_history: %O\n", Calendar.now()->format_time_xshort(), p->data));
  sendmsg(p->data["_group"], PSYC.Packet("_request_history"));
  return PSYC.Handler.STOP;
}

int postfilter_request_do_invite(MMP.Packet p, mapping _v, mapping _m)
{
  debug("Person", 0, sprintf("[%s]PERSON: _request_do_invite: %O\n", Calendar.now()->format_time_xshort(), p->data));
  sendmsg(p->data["_person"], PSYC.Packet("_notice_invitation", (["_place":p->data["_focus"] ]), p->data->data));
  return PSYC.Handler.STOP;
}

int postfilter_request_do_log_email(MMP.Packet p, mapping _v, mapping _m)
{
  debug("Person", 0, sprintf("[%s]PERSON: _request_do_log_email: %O\n", Calendar.now()->format_time_xshort(), p->data));

  if(MMP.is_place(p->data["_group"]))
  {
    send_tagged(p->lsource(),
                PSYC.Packet("_request_retrieve", ([ "_key":"_identification_scheme_mailto" ])),
                lambda(MMP.Packet r, mixed ... args)
                {
                  debug("Email", 3, sprintf("%O\n", (string)r->data));
                  send_tagged(p->data["_group"],PSYC.Packet("_request_history_log"),
                                lambda(MMP.Packet r, mixed ... args)
                                {
                                  debug("Email", 3, sprintf("%O:%O\n", (string)r->data, args));
                                  return PSYC.Handler.STOP;
                                });
                  return PSYC.Handler.STOP;
                });


//                  Thread.Thread(lambda(){ Protocols.SMTP.Client(mailserver)->simple_mail(p->data["_email_address"], "Your Hyundai chatlog", "customerservice@hyundai.co.nz", logtext); });
//    sendmsg(p->data["_group"], PSYC.Packet("_request_log_email", (["_email_address":p->data["_email_address"]])));
  } else {
    debug("Person", 0, "%O is not a place. stopping.\n", p->data["_group"]);
  }
  return PSYC.Handler.STOP;
}
