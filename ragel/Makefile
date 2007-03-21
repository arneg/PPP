RAGEL = ragel
RLCODEGEN = rlgen-cd -G2

ifdef V
    VERSION = $(V)
else
    VERSION = 0.2
endif

all: psyc

ps: psyc.ps

ps: psyc.o 
	gcc -g -o psyc psyc.o

pike: psyc.rl
	$(RAGEL) -e psyc.rl | $(RLCODEGEN) -o cmod/psyc.cmod && (cd cmod/ && pike -x module)

psyc.c: psyc.rl
	$(RAGEL) psyc.rl | $(RLCODEGEN) -o psyc.c

psyc.ps: psyc.rl
	$(RAGEL) psyc.rl | rlgen-dot -p | dot -Tps > psyc.ps

json_string.c: json_string.rl
	$(RAGEL) json_string.rl | $(RLCODEGEN) -o json.cmod/json_string.c

json_mapping.c: json_mapping.rl
	$(RAGEL) json_mapping.rl | $(RLCODEGEN) -o json.cmod/json_mapping.c

json_array.c: json_array.rl
	$(RAGEL) json_array.rl | $(RLCODEGEN) -o json.cmod/json_array.c

json_number.c: json_number.rl
	$(RAGEL) json_number.rl | $(RLCODEGEN) -o json.cmod/json_number.c

json.cmod: json_string.c json_mapping.c json_array.c json_number.c
	$(RAGEL) -e json.rl | $(RLCODEGEN) -o json.cmod/json.cmod

json.o: json.cmod 
	(cd json.cmod/ && pike -x module)

json.ps: json.rl json_string.rl json_mapping.rl json_array.rl json_number.rl
	$(RAGEL) json.rl | rlgen-dot -p | dot -Tps > json.ps
	$(RAGEL) json_string.rl | rlgen-dot -p | dot -Tps > json_string.ps
	$(RAGEL) json_mapping.rl | rlgen-dot -p | dot -Tps > json_mapping.ps
	$(RAGEL) json_array.rl | rlgen-dot -p | dot -Tps > json_array.ps
	$(RAGEL) json_number.rl | rlgen-dot -p | dot -Tps > json_number.ps

%.o: %.c
	gcc -Wall -O3 -g -c -o $@ $<

distclean clean:
	rm -Rf *.o psyc.c psyc psyc.ps
test:
	pike -I../lib -M../lib test_json.pike
release: json.cmod
	mkdir Public_Parser_JSON2-$(VERSION)
	cp json.cmod/Makefile.in Public_Parser_JSON2-$(VERSION)/
	cp json.cmod/configure.in Public_Parser_JSON2-$(VERSION)/
	cp json.cmod/json_*.c Public_Parser_JSON2-$(VERSION)/
	cp json.cmod/json.h Public_Parser_JSON2-$(VERSION)/
	cp json.cmod/json.cmod Public_Parser_JSON2-$(VERSION)/
	cp json.cmod/README Public_Parser_JSON2-$(VERSION)/
	cp json.cmod/LICENSE Public_Parser_JSON2-$(VERSION)/
	cp json.cmod/CHANGES Public_Parser_JSON2-$(VERSION)/
	cp json.cmod/module.pmod.in -r Public_Parser_JSON2-$(VERSION)/
	cp json.cmod/testsuite.in Public_Parser_JSON2-$(VERSION)/
	mkdir Public_Parser_JSON2-$(VERSION)/ragel
	cp json*.rl Public_Parser_JSON2-$(VERSION)/ragel/
test_clear:
	rm Public_Parser_JSON2-test -rf
json_build: test_clear
	make V=test release && cd Public_Parser_JSON2-test && pike -x module && tail ../Makefile --lines=4 >> Makefile
json_test: json_build
	cd Public_Parser_JSON2-test && pike -x module verify 
json_install: json_build
	cd Public_Parser_JSON2-test && sudo pike -x module install

again:
	$(COMMAND)
COMMAND = cd .. && exec make test_clear test_json& 
