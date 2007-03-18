RAGEL = ragel
RLCODEGEN = rlgen-cd -G2

ifdef V
    VERSION = $(V)
else
    VERSION = 0.1
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
	$(RAGEL) psyc.rl | rlgen-dot | dot -Tps > psyc.ps

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
	$(RAGEL) json.rl | rlgen-dot | dot -Tps > json.ps
	$(RAGEL) json_string.rl | rlgen-dot | dot -Tps > json_string.ps
	$(RAGEL) json_mapping.rl | rlgen-dot | dot -Tps > json_mapping.ps
	$(RAGEL) json_array.rl | rlgen-dot | dot -Tps > json_array.ps
	$(RAGEL) json_number.rl | rlgen-dot | dot -Tps > json_number.ps

%.o: %.c
	gcc -Wall -O3 -g -c -o $@ $<

distclean clean:
	rm -Rf *.o psyc.c psyc psyc.ps
test:
	pike -I../lib -M../lib test_json.pike
release:
	mkdir Public_Parser_JSON2-$(VERSION)
	cp json.cmod/Makefile.in Public_Parser_JSON2-$(VERSION)/
	cp json.cmod/configure.in Public_Parser_JSON2-$(VERSION)/
	cp json.cmod/json_*.c Public_Parser_JSON2-$(VERSION)/
	cp json.cmod/json.cmod Public_Parser_JSON2-$(VERSION)/
	cp json.cmod/README Public_Parser_JSON2-$(VERSION)/
	cp json.cmod/LICENSE Public_Parser_JSON2-$(VERSION)/
	cp json.cmod/module.pmod.in -r Public_Parser_JSON2-$(VERSION)/
	mkdir Public_Parser_JSON2-$(VERSION)/ragel
	cp json*.rl Public_Parser_JSON2-$(VERSION)/ragel/
