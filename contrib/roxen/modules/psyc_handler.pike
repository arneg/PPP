// This is a roxen module. (c) webhaven 2007
//
//  a module to provide psyc handlers

#include <module.h>
inherit "module";
inherit "roxenlib";

static private string doc()
{
  return "manage psyc handlers\n";
}

array register_module()
{
  return ({ MODULE_PROVIDER, "psyc:handler",
            doc() });
}

array|string query_provides()
{
  return "psyc";
}

Sql.Sql sql;
string mailserver;
string sqlserver;

void create()
{
  sqlserver = my_configuration()->call_provider("webhaven", "query", "thedatabase");
  if (sqlserver)
  {
    set_my_db(sqlserver);
    sql = get_my_sql();
  }

  mailserver = my_configuration()->call_provider("webhaven", "query", "global_mailserver");
}

array get_handlers(MMP.Uniform uni, mapping params)
{
  array handlers = ({});
  if (MMP.is_person(uni)) {
      handlers += ({ PSYC.Handler.Do(params), PSYCLocal.Person(params) });
  }

  return handlers;
}

array get_channel_handlers(MMP.Uniform uni, mapping params)
{
  werror("get_channel_handlers(%O)\n", uni);

  array handlers = ({});
  if (MMP.is_place(uni)) {
      handlers += ({ PSYCLocal.Place(params + ([ "sql":sql, 
                                                 "sqlserver":sqlserver, 
                                                 "mailserver":mailserver ])) });
  }

  return handlers;
}
