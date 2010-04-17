// i am a medium pie

#ifndef BIND
# define BIND ""
#endif

#ifndef PORT
# define PORT 4044 // in your face!
#endif

object server;

int main(int argc, array(string) argv) {
    object stdin, stdout, hilfe;

    server = MMP.Server(([ "bind" : (stringp(BIND) && sizeof(BIND)) ? sprintf("%s:%d", BIND, PORT) : PORT ]));

    stdin = Stdio.File();
    stdin->assign(Stdio.stdin);
    stdout = Stdio.File();
    stdout->assign(Stdio.stdout);

    hilfe = MMP.Utils.Hilfe(stdin, stdout);
    hilfe->variables->server = server;
    hilfe->variables->main = this;
    hilfe->variables->a = PSYC.Base(server, server->get_uniform("psyc://localhost/~a"));
    hilfe->variables->b = PSYC.Base(server, server->get_uniform("psyc://localhost/~b"));
    server->register_entity(hilfe->variables->a->uniform, hilfe->variables->a);
    server->register_entity(hilfe->variables->b->uniform, hilfe->variables->b);

    return -1;
}
