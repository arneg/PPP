Stdio.File socket;
string peeraddr, peerhost, host;
int peerport, port;

void create(Stdio.File so, string|void host, int|void port) {
    array(string) temp;
    socket = so;

    peeraddr = so->query_address(1);
    if (!peeraddr) {
	// socket not connected..
	return;
    }
    temp = peeraddr / " ";
    host = temp[0];
    port = (int)temp[1];

    peeraddr = so->query_address(0);
    temp =  peeraddr / " ";
    peerhost = temp[0];
    peerport = (int)temp[1];

}

