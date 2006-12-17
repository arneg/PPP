// vim:syntax=lpc
//
PSYC.Server dings;
TELNET.Server da;

#ifdef HAS_XMPP
XMPP.S2S.ClientManager rumms;
XMPP.S2S.ServerManager bumms;
#endif

#ifndef BIND
# define BIND	"127.0.0.1"
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
    string smtime() {
	string wday, month;
	mapping t = localtime(time()),
		t2 = gmtime(sgn(t->timezone) * t->timezone);

	switch (t->wday) {
	case 0:
	    wday = "Sun";
	    break;
	case 1:
	    wday = "Mon";
	    break;
	case 2:
	    wday = "Tue";
	    break;
	case 3:
	    wday = "Wed";
	    break;
	case 4:
	    wday = "Thu";
	    break;
	case 5:
	    wday = "Fri";
	    break;
	case 6:
	    wday = "Sat";
	    break;
	}

	switch (t->mon) {
	case 0:
	    month = "Jan";
	    break;
	case 1:
	    month = "Feb";
	    break;
	case 2:
	    month = "Mar";
	    break;
	case 3:
	    month = "Apr";
	    break;
	case 4:
	    month = "May";
	    break;
	case 5:
	    month = "Jun";
	    break;
	case 6:
	    month = "Jul";
	    break;
	case 7:
	    month = "Aug";
	    break;
	case 8:
	    month = "Sep";
	    break;
	case 9:
	    month = "Oct";
	    break;
	case 10:
	    month = "Nov";
	    break;
	case 11:
	    month = "Dec";
	    break;
	}

	return sprintf("%s, %d %s %d %02d:%02d:%02d %c%02d%02d",
		       wday, t->mday, month, 1900 + t->year,
		       t->hour, t->min, t->sec,
		       sgn(t->timezone) < 0 ? '+' : '-',
		       t2->hour, t2->min);
    };

    dings = PSYC.Server(([
	     "ports" : ({ 
		       (MMP.Utils.Net.is_ip(LOCALHOST) ? LOCALHOST : BIND) 
			+ ":4404" }),
      "create_local" : create_local,
    "deliver_remote" : deliver_remote,
    "module_factory" : create_module,
     "offer_modules" : ({ "_compress" }),
 "default_localhost" : HOSTNAME,
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
		       (MMP.Utils.Net.is_ip(LOCALHOST) ? LOCALHOST : BIND) 
			+ ":2000" }),
	     "textdb" : textdb,
			]));

    write("220 ppp ESMTP Sendmail 8.13.7/8.13.7; %s\nlocalhost: %s\n", smtime(), LOCALHOST);
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
