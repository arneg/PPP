#include <debug.h>
inherit PSYC.Handler.Base;

//! This handler logs every message received.
//!
//! Requires no variables from storage whatsoever.

constant _ = ([
    "prefilter" : ([
	"" : 0,
    ]),
    "postfilter" : ([
	"" : 0,
    ]),
    "display" : ([
	"" : 0,
    ]),
]);

mapping sessions = ([]);
object sql;

int prefilter(MMP.Packet p, mapping _v, mapping _m) 
{
  return logger("prefilter", p, _v, _m);
}

int postfilter(MMP.Packet p, mapping _v, mapping _m) 
{
  return logger("postfilter", p, _v, _m);
}

int display(MMP.Packet p, mapping _v, mapping _m) 
{
  return logger("display", p, _v, _m);
}

int logger(string label, MMP.Packet p, mapping _v, mapping _m) 
{
    array debugdata = ({
      ({ "parent",parent }),
      ({ "p->data",p->data }),
      ({ "(string)p->data",(string)p->data }),
      ({ "p->data[\"_group\"]",p->data["_group"] }),
      ({ "p->data[\"_supplicant\"]",p->data["_supplicant"] }),
      ({ "parent->qName()==p->data[\"_supplicant\"]",(string)(parent->qName()==p->data["_supplicant"]) }),
      ({ "p->data->data",p->data->data }),
      ({ "p->source()",p->source() }),
      ({ "p->lsource()",p->lsource() }),
      ({ "p->vars",p->vars }),
      ({ "_m",_m }),
      ({ "_v",_v }),
      ({ "p->data",p->data }),
      ({ "(string)p->data",(string)p->data }),
    });
    string debugout = "";
    foreach(debugdata;; array data)
    {
      [string key, mixed value] = data;
      if(value && !((mappingp(value)||arrayp(value)) && !sizeof(value)))
        debugout += sprintf("\n    %s:%O", key, value);
    }
    write("\n[%s]%s%s\n", Calendar.now()->format_time_xshort(), label, debugout);

    return PSYC.Handler.GOON;
}
