/* 
 * translate XMPP to PSYC - whenever possible
 */
void handle(XMPP.Node node) {
    XMPP.Node fc;
    int typeflag;

    /* as semantic is different depending on what the target is 
     * (like person/room) we need to know this
     */
    switch(node["to"][0]) {
    }
    switch(node->getName()) {
    case "message":
	switch(node->type) {
	case 0: /* no type */
	    break;
	case "error":
	    break;
	}
	break;
    case "iq":
	fc = node->firstChild();
	if (fc) {
	    /* wenn du nen handler fuer den xmlns hast, dann hau rein */
	} else {
	    switch(node->type) {
	    case "result":
	    case "error":
		/* achtung, callback anhand von _tag in id aufrufen*/ 
	    default: 
		/* die spec sagt, dass ein iq get/setein kind haben muss
		 * also kommt hier ein fehler hin
		 */
	    }
	}
	break;
    case "presence":
	/* tollerweise ist die semantik teilweise dadurch bestimmt was 
	 * das ziel ist - z.b. kann normale presence sowohl
	 * notice friend present als auch request enter sein
	 * oder im fall von raeumen auch ein statuschange an den rau
	 */
	switch(node["type"]) {
	case 0: /* no type */
	    break;
	case "probe":
	    break;
	case "subscribe":
	    break;
	case "unsubscribe":
	    break;
	case "subscribed":
	    break;
	case "unsubscribed":
	    break;
	}
	break;
    default:
	/* look if there is a stanza handler for this
	 * call unknown stanza handler if everything else fails
	 */
    }
}
