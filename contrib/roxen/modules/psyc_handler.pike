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

void create()
{
  set_my_db(my_configuration()->call_provider("webhaven", "query", "thedatabase"));
  sql = get_my_sql();

  mailserver = my_configuration()->call_provider("webhaven", "query", "global_mailserver");
}

array get_handlers(int type, mapping params)
{
// TODO: query roxen database variable, and instantiate Logger handler,
// return instantiated handler with params and database variable

  array handlers = ({});
  switch(type)
  {
    case '~':
      handlers += ({ PSYC.Handler.Do(params), PSYCLocal.Person(params) });
      break;
    case '@':
      handlers += ({ PSYCLocal.Place(params + ([ "sql":sql, "mailserver":mailserver ])) });
      break;
  }
  //handlers += ({ PSYCLocal.Logger(params) });

  return handlers;
}
