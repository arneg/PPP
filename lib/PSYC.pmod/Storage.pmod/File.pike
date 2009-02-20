// vim:syntax=lpc
inherit .Volatile;

string filename;

//! Storage class that operates on @[FlatFile].

//! @param filename
//! 	Name of the file that contains the serialized mappinglike structure.
//! 	If the file is empty, this storage class operates on @expr{([ ])@}.
//! 	The file will then be created when data is saved.
void create(string filename, object signature) {
    this_program::filename = filename;
    Serialization.AtomParser parser = Serialization.AtomParser();

    if (!Stdio.is_file(filename)) {
	Stdio.mkdirhier(dirname(filename));
	raw_data = data = ([]);
    } else {
	string fdata = Stdio.read_file(filename);
	array t = Serialization.parse_atoms(fdata);

	if (sizeof(t) != 1) {
	    error("Broken storage file: %s.\n", filename);
	}

	raw_data = signature->decode(t[0]);
	data = ([]);
    }
}

void save() {
    Stdio.write_file(filename, render());
}
