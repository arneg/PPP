.PHONY: ppp refdoc refdoc-publish
ifndef S
    S = fickzoo
endif

ifdef TN
    override TN = -DLOVE_TELNET
endif

ifdef D
    DEBUG = -DDEBUG=$(D)
endif

ifdef L
    LOCALHOST = -DLOCALHOST="\"$(L)\""
endif

ifdef B
    BIND = -DBIND="\"$(B)\""
endif

ifdef TP
    TDB = -DTEXT_DB_PATH="\"$(TP)\""
endif

ifdef DP
    DPP = -DDATA_PATH="\"$(DP)\""
endif

ppp:
	pike -DSTILLE_DULDUNG -DLOVE_JSON $(TN) -Ilib -Mlib $(BIND) $(DEBUG) $(LOCALHOST) $(TDB) $(DPP) $(S).pike

refdoc:
	- rm -r refdoc refdoc_tmp
	mkdir refdoc_tmp
	cp Makefile.in.refdoc refdoc_tmp/Makefile.in
	cp configure.in.refdoc refdoc_tmp/configure.in
	cp -R lib/PSYC.pmod refdoc_tmp/module.pmod.in
	- cd refdoc_tmp ; pike -x module ; pwd ; pike -x module module_modref
	mv refdoc_tmp/refdoc .
	rm -r refdoc_tmp

refdoc-publish: refdoc
	- rm -r /www/main/k/refdoc
	cp -R refdoc /www/main/k
