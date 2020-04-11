DARTC=dart2native
OUTDIR=~/bin
SRC=bin/xftts.dart bin/gen_readme.dart
BIN=$(SRC:bin/%.dart=%)

all: $(BIN)
	@mv $(BIN) $(OUTDIR)

$(BIN):%:bin/%.dart
	@echo "Creating $@ with $<."
	-@$(DARTC) $< -o $@