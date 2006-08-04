// vim:syntax=lpc
//
PSYC.Server dings;
XMPP.S2S.Server bumms;

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
	"localhosts" : ([ "localhost" : 1 ]),
	"ports" : ({ "localhost:4404" }),
	"create_local" : create_local,
	"create_remote" : lambda(mixed ... args) { },
	"module_factory" : create_module,
	"offer_modules" : ({ "_compress" }),
	 ]));
    bumms = XMPP.S2S.Server(([
	"localhosts" : ([ "localhost" : 1 ]),
	"ports" : ({ "localhost:5222" }),
	"key" : ([ "localhost" : my_key ]),
	"certificates" : ([ "localhost" : my_certificate ]),
	"create_local" : create_local,
	"create_remote" : lambda(mixed ... args) { },
	"module_factory" : create_module,
	"offer_modules" : ({ "_compress" }),
	 ]));
    return -1;
}

// does _not_ check whether the uni->host is local.
object create_local(MMP.Uniform uni) {
    object o;
    if (sizeof(uni->resource) > 1) switch (uni->resource[0]) {
    case '~':
	// TODO check for the path...
	o = User.Person(uni->resource[1..], uni, dings);
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
