// vim:syntax=lpc
#include <debug.h>
inherit .Volatile;
//import PSYC.Storage;

void create(string filename) {
    ::create(.FlatFile(filename));
}
