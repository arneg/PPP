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

ppp:
	pike -DSTILLE_DULDUNG $(TN) -Ilib -Mlib $(BIND) $(DEBUG) $(LOCALHOST) $(S).pike
