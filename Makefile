DARTC=dart2native
OUTDIR=/Users/tchen/bin
SRC=bin/podgen.dart
BIN=$(SRC:bin/%.dart=$(OUTDIR)/%)

all: $(BIN)

$(BIN):$(OUTDIR)/%:bin/%.dart
	@echo "Creating $@ with $<."
	-@$(DARTC) $< -o $@
