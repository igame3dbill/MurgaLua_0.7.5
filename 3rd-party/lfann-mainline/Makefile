# Compiler and flags
CC=gcc
LUAC=luac
PKG_PACKAGES=lua
CFLAGS=-shared -pipe -Wall `pkg-config --cflags $(PKG_PACKAGES)`
LDFLAGS=-shared `pkg-config --libs $(PKG_PACKAGES)` -ldoublefann

ifdef DEBUG
	CFLAGS+=-g -O0 -DIDEBUG
else
	CFLAGS+=-O2
endif

ifdef AMD64
	CFLAGS+=-fPIC -DAMD64
else
	CFLAGS+=-fpic
endif

# Platform dependent
RM=rm -rf
CP=cp
MKDIR=mkdir -p
DESTDIR=/usr/local
NAME=lfann.so

# Rules

.PHONY: all
all: $(SOURCES) $(NAME)

$(NAME): src/interface.c src/data.c src/extension.c src/lfann.h src/net.c
	$(CC) $(CFLAGS) src/interface.c -o $@ $(LDFLAGS)

.PHONY: install
install: all
	$(MKDIR) $(DESTDIR)/lib/lua/5.1
	$(CP) $(NAME) $(DESTDIR)/lib/lua/5.1

.PHONY: clean
clean:
	$(RM) $(NAME)

.PHONY: help
help:
	@echo Options:
	@echo
	@echo AMD64=1 to build for 64 bits
	@echo DEBUG=1 to enable debug mode
