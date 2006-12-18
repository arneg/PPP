inherit PSYC.Unl;

void create(MMP.Uniform uniform, object server) {
    
    ::create(uniform, server, PSYC.DummyStorage());
    add_handlers(PSYC.Handler.Channel(this));
}

void add(MMP.Uniform guy, function cb, mixed ... args) {
    call_out(cb, 0, @args);
}
