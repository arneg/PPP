// vim:syntax=lpc
//
PSYC.Server dings;
XMPP.S2S.Server bumms;
TELNET.Server da;
#ifndef LOCALHOST
# define LOCALHOST "localhost"
#endif

string my_certificate = MIME.decode_base64(
  "MIIBxDCCAW4CAQAwDQYJKoZIhvcNAQEEBQAwbTELMAkGA1UEBhMCREUxEzARBgNV\n"
  "BAgTClRodWVyaW5nZW4xEDAOBgNVBAcTB0lsbWVuYXUxEzARBgNVBAoTClRVIEls\n"
  "bWVuYXUxDDAKBgNVBAsTA1BNSTEUMBIGA1UEAxMLZGVtbyBzZXJ2ZXIwHhcNOTYw\n"
  "NDMwMDUzNjU4WhcNOTYwNTMwMDUzNjU5WjBtMQswCQYDVQQGEwJERTETMBEGA1UE\n"
  "CBMKVGh1ZXJpbmdlbjEQMA4GA1UEBxMHSWxtZW5hdTETMBEGA1UEChMKVFUgSWxt\n"
  "ZW5hdTEMMAoGA1UECxMDUE1JMRQwEgYDVQQDEwtkZW1vIHNlcnZlcjBcMA0GCSqG\n"
  "SIb3DQEBAQUAA0sAMEgCQQDBB6T7bGJhRhRSpDESxk6FKh3iKKrpn4KcDtFM0W6s\n"
  "16QSPz6J0Z2a00lDxudwhJfQFkarJ2w44Gdl/8b+de37AgMBAAEwDQYJKoZIhvcN\n"
  "AQEEBQADQQB5O9VOLqt28vjLBuSP1De92uAiLURwg41idH8qXxmylD39UE/YtHnf\n"
  "bC6QS0pqetnZpQj1yEsjRTeVfuRfANGw\n");

string my_key = MIME.decode_base64(
  "MIIBOwIBAAJBAMEHpPtsYmFGFFKkMRLGToUqHeIoqumfgpwO0UzRbqzXpBI/PonR\n"
  "nZrTSUPG53CEl9AWRqsnbDjgZ2X/xv517fsCAwEAAQJBALzUbJmkQm1kL9dUVclH\n"
  "A2MTe15VaDTY3N0rRaZ/LmSXb3laiOgBnrFBCz+VRIi88go3wQ3PKLD8eQ5to+SB\n"
  "oWECIQDrmq//unoW1+/+D3JQMGC1KT4HJprhfxBsEoNrmyIhSwIhANG9c0bdpJse\n"
  "VJA0y6nxLeB9pyoGWNZrAB4636jTOigRAiBhLQlAqhJnT6N+H7LfnkSVFDCwVFz3\n"
  "eygz2yL3hCH8pwIhAKE6vEHuodmoYCMWorT5tGWM0hLpHCN/z3Btm38BGQSxAiAz\n"
  "jwsOclu4b+H8zopfzpAaoB8xMcbs0heN+GNNI0h/dQ==\n");

int main(int argc, array(string) argv) {

    dings = PSYC.Server(([
	"localhosts" : ([ LOCALHOST : 1 ]),
	     "ports" : ({ LOCALHOST + ":4404" }),
      "create_local" : create_local,
    "deliver_remote" : deliver_remote,
    "module_factory" : create_module,
     "offer_modules" : ({ "_compress" }),
 "default_localhost" : LOCALHOST,
	 ]));
// maybe this is better for you, fippo
// just remove the ifdef whenever you think XMPP could be used
#ifdef XMPP
    bumms = XMPP.S2S.Server(([
	"localhosts" : ([ "localhost" : 1 ]),
	     "ports" : ({ "localhost:5222" }),
	       "key" : ([ "localhost" : my_key ]),
      "certificates" : ([ "localhost" : my_certificate ]),
      "create_local" : dings->get_local,
     "offer_modules" : ({ "_compress" }),
	 ]));
#endif
    da = TELNET.Server(([
	 "psyc_server" : dings,
	     "ports" : ({ LOCALHOST + ":2000" }),
			]));

    write("220 ppp ESMTP Sendmail 8.13.7/8.13.7;\n");
    return -1;
}

void deliver_remote(MMP.Packet p, MMP.Uniform target) {
    
    switch (target->scheme) { 
    case "psyc":
	dings->deliver_remote(p, target);	
	break;
    case "xmpp":
	// your code here.
    }
}

// does _not_ check whether the uni->host is local.
object create_local(MMP.Uniform uni) {
    object o;
    if (sizeof(uni->resource) > 1) switch (uni->resource[0]) {
    case '~':
	// TODO check for the path...
	o = PSYC.Person(uni->resource[1..], uni, dings);
	return o;
	break;
    case '@':
	return Place.Basic(uni, dings);
	break;
    case '$':
    }
}


// we transmit the variables of the neg packet. i dont have a better idea
// right now
object create_module(string name, mapping vars) {

    switch (name) {
    case "_compress":
	
    case "_encrypt":

    }

}
