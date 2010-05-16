void create(object server, MMP.Uniform uniform) {}
void sendmsg(MMP.Uniform target, string method, void|string data, void|mapping vars, void|function callback);
void send(MMP.Uniform target, Serialization.Atom m, void|mapping vars, void|function callback);
void sendreply(MMP.Packet p, Serialization.Atom m, void|mapping vars, void|function callback);
void sendreplymsg(MMP.Packet p, string method, void|string data, void|mapping vars, void|function callback);
