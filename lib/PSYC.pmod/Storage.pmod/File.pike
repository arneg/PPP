// vim:syntax=lpc
inherit .Volatile;

//! Storage class that operates on @[FlatFile].

//! @param filename
//! 	Name of the file that contains the serialized mappinglike structure.
//! 	If the file is empty, this storage class operates on @expr{([ ])@}.
//! 	The file will then be created when data is saved.
void create(string filename) {
    Serialization.AtomParser parser = Serialization.AtomParser();

    if (!Stdio.is_file(filename)) {
	Stdio.mkdirhier(dirname(filename));
	raw_data = data = ([]);
    } else {
	string fdata = Stdio.read_file(filename);
	raw_data = parser->parse_all(fdata);

	if (parser->left()) {
	    error("Data in file %s seems to be broken.\n", filename);
	}

	data = ([]);
    }
}

void save() {
    Stdio.write_file(filename, render());
}
