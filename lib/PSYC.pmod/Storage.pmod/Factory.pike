//! Factories manage access to storage objects.

mapping storages;

//! An innocent little @[create()] here, but keep in mind that you
//! @b{definitely want to call this from inhering classes@}.
void create() {
    storages = set_weak_flag(([ ]), Pike.WEAK);
}

//! Gets called when a storage object for the given @expr{uniform@} can't be
//! found and a new one needs to be created.
//! @note
//! 	Abstract. Needs to be overlaoded in subclasses. Keep in mind that you
//! 	probably don't want to call this method on your own, you just need to
//! 	provide it when you are inheriting this class.
.Volatile createStorage(MMP.Uniform); 

//! @param storagee
//! 	The entity you want the storage object for/of.
//! @returns
//! 	The matching storage object.
.Volatile getStorage(MMP.Uniform storagee) {
    if (has_index(storages, storagee)) {
	return storages[storagee];
    } else {
	return storages[storagee] = createStorage(storagee);
    }
}
