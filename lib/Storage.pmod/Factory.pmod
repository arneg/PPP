mapping storages = ([ ]);

.module.Storage getStorage(string type, string name) {
    mapping t;

    if (!mappingp(t = storages[type])) {
	t = storages[type] = ([ ]);

	set_weak_flag(t, Pike.WEAK_VALUES);
    }

    if (has_index(t, name)) {
	return t[name];
    }

    void cb() { m_delete(t, name); };

    return t[name] =
	    .module.FlatFile(DATA_PATH + type + "/" + name + DATA_EXT, cb);
}
