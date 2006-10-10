inherit PSYC.MethodMultiplexer;
PSYC.Storage storage = PSYC.DummyStorage();

void create(MMP.Uniform uni) {
    ::create(storage); 
    add_handlers(PSYC.DemoHandler());
}
