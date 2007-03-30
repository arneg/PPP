// vim:syntax=lpc
#include <debug.h>
inherit .Volatile;

//! Storage class that operates on @[FlatFile].

//! @param filename
//! 	Name of the file that contains the serialized mappinglike structure.
//! 	If the file is empty, this storage class operates on @expr{([ ])@}.
//! 	The file will then be created when data is saved.
//! @param codec
//! 	Codec object to use for serialization of @[MMP.Uniform] objects.
void create(string filename, object codec) {
    ::create(.FlatFile(filename, codec));
}

void save() {
    data->save();
}
