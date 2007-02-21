mixed _destructstorecb;

void destroy() {
    if (_destructstorecb) {
	_destructstorecb();
    }
}
