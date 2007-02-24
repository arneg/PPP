// vim:syntax=lpc
#include <debug.h>
inherit .Volatile;

//! Storage class that operates on @[FlatFile].

//! @param filename
//! 	Name of the file that contains the serialized mappinglike structure.
//! 	If the file is empty, this storage class operates on @expr{([ ])@}.
//! 	The file will then be created when data is saved.
void create(string filename) {
    ::create(.FlatFile(filename));
}

void save() {
    data->save();
}
