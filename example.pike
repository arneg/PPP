// vim:syntax=lpc
//
PSYC.Server dings;
TELNET.Server da;
PSYC.Storage.Factory dumms;

#ifdef HAS_XMPP
XMPP.S2S.ClientManager rumms;
XMPP.S2S.ServerManager bumms;
#endif

#ifndef HOSTNAME
# ifdef LOCALHOST
#  define HOSTNAME	LOCALHOST
# else
#  define HOSTNAME	"localhost"
# endif
#endif
#ifndef LOCALHOST // for XMPP
# define LOCALHOST	HOSTNAME
#endif
#ifndef REMOTEHOST
# define REMOTEHOST	"localhost"
#endif

#if HAS_XMPP
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
#endif


int main(int argc, array(string) argv) {
    function textdb = PSYC.Text.FileTextDBFactoryFactory(
#ifdef TEXT_DB_PATH
							 TEXT_DB_PATH
#else
							 "../default/"
#endif
							 );

    dumms = PSYC.Storage.FileFactory(DATA_PATH); 

    object debug = MMP.Utils.DebugManager();
    debug->set_default_backtrace(1);
    debug->set_default_debug(3);
    dings = PSYC.Server(([
	     "ports" : ({ 
#ifdef BIND
			BIND
#elif defined(LOCALHOST)
			LOCALHOST
#endif
			+ ":4404" }),
	     "debug" : debug,
	   "storage" : dumms,
      "create_local" : create_local,
     "offer_modules" : ({ "_compress" }),
    "deliver_remote" : deliver_remote,
    "module_factory" : create_module,
 "default_localhost" : HOSTNAME,
#if DEFINED(BIND) && BIND != HOSTNAME
	"localhosts" : ({ BIND }),
#endif
	    "textdb" : textdb,
	 ]));
#ifdef HAS_XMPP
    XMPP.S2S.Client flumms;

    bumms = XMPP.S2S.ServerManager(([
	"localhosts" : ([ LOCALHOST : 1 ]),
	     "ports" : ({ 5269 }),
	"tls" : ([ "key" : ([ LOCALHOST : my_key ]),
		 "certificates" : ([ LOCALHOST : my_certificate ]),
		 ]),
     "secret" : "thesecret"
	 ]));
    rumms = XMPP.S2S.ClientManager(([
	"localhosts" : ([ LOCALHOST : 1 ]),
	"tls" : ([ "key" : ([ LOCALHOST : my_key ]),
		 "certificates" : ([ LOCALHOST : my_certificate ]),
		 ]),
     "secret" : "thesecret"
	 ]));
#endif
    da = TELNET.Server(([
	 "psyc_server" : dings,
	     "ports" : ({ 
#ifdef BIND
			BIND
#elif defined(LOCALHOST)
			LOCALHOST
#endif
			+ ":2000" }),
	     "textdb" : textdb,
			]));

    write("220 %s ESMTP Sendmail 8.13.7/8.13.7; %s\n", LOCALHOST, Calendar.ISO.now()->format_smtp());
    return -1;
}

void deliver_remote(MMP.Packet p, MMP.Uniform target) {
    
    switch (target->scheme) { 
    case "psyc":
	dings->deliver_remote(p, target);	
	break;
#ifdef HAS_XMPP
    case "xmpp":
	rumms->deliver_remote(p, target);
	break;
#endif
    }
}

// does _not_ check whether the uni->host is local.
object create_local(mapping params) {

    MMP.Uniform uni = params["uniform"];

    write("creating object for %O.\n", uni);
    if (uni->resource && sizeof(uni->resource) > 1) {

	switch (uni->resource[0]) {
	case '~':
	    // TODO check for the path...
	    params += ([ "storage" : params["storage_factory"]->getStorage(uni) ]);
	    return PSYC.Person(params);
	case '@':
	    params += ([ "storage" : params["storage_factory"]->getStorage(uni) ]);
	    return PSYC.Place(params);
	default:
	    return 0;
	}
    } else {
	params += ([ "storage" : params["storage_factory"]->getStorage(uni) ]);
	return PSYC.Root(params);
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
