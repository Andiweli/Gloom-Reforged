# Uses the same AmigaOS GCC/AmiSSL SDK setup as AmiMAIL. No ixemul required.
ifeq ($(origin CC),default)
CC := m68k-amigaos-gcc
endif
AMISSL_SDK ?= /opt/amiga/m68k-amigaos/amissl
CPPFLAGS += -I. -I$(AMISSL_SDK)/include -D__USE_INLINE__ -D__USE_BASETYPE__
CFLAGS += -std=gnu99 -noixemul -m68020 -msoft-float -Os -fomit-frame-pointer -Wall -Wextra
SOURCES := worker.c release.c http.c tls.c buffer.c common.c
GloomUpdate: $(SOURCES) release.h tls.h buffer.h amigmail.h compat.h
	$(CC) $(CPPFLAGS) $(CFLAGS) -o $@ $(SOURCES)
clean:
	rm -f GloomUpdate
.PHONY: clean
