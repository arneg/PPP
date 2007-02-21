mapping storages = ([ ]);

void create() {
    set_weak_flag(storages, Pike.WEAK);
}

.Volatile createStorage(MMP.Uniform); 

.Volatile getStorage(MMP.Uniform storagee) {
    if (has_index(storages, storagee)) {
	return storages[storagee];
    } else {
	return storages[storagee] = createStorage(storagee);
    }
}
