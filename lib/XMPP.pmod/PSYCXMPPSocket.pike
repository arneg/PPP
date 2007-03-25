/*
 * Socket object which translates (guesses) XMPP to PSYC and vice versa
 */

inherit XMPP.XMPPSocket;
inherit XMPP.XMPP2PSYC;
inherit XMPP.PSYC2XMPP;
void create(mapping(string:mixed) config) {
    XMPPSocket::create(config);
}

void handle(XMPP.Node node) {
    XMPP2PSYC::handle(node);
}
