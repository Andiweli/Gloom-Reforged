VASM ?= vasmm68k_mot
VLINK ?= vlink
PYTHON ?= python3
CPU ?= -m68020
VASMFLAGS ?= $(CPU) -devpac -nocase -Fhunk -I. -Ibuild_vasm
LDFLAGS ?= -bamigahunk

.PHONY: build-one clean

build-one:
	@mkdir -p build_vasm
	$(PYTHON) tools/normalize_gloom_source.py $(SRC) build_vasm/$(SRC)
	$(VASM) $(VASMFLAGS) -o build_vasm/$(SRC).o build_vasm/$(SRC)
	$(VLINK) $(LDFLAGS) -o $(OUT) build_vasm/$(SRC).o

clean:
	rm -rf build_vasm
	rm -f *.o Gloom Gloom2 Gloom_ap
