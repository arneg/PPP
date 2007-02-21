.PHONY: ppp
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
