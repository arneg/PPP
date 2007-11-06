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
      handlers += ({ PSYCLocal.Place(params) });
      break;
  }
  //handlers += ({ PSYCLocal.Logger(params) });

  return handlers;
}
