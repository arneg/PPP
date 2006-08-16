.PHONY: ppp
ifndef S
    S = fickzoo
endif

ifdef D
    DEBUG = -DDEBUG=$(D)
endif

ifdef L
    LOCALHOST = -DLOCALHOST="\"$(L)\""
endif

ppp:
	pike -DSTILLE_DULDUNG -Ilib -Mlib $(DEBUG) $(LOCALHOST) $(S).pike
