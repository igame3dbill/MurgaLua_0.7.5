# This file is part of Mongoose project, http://code.google.com/p/mongoose
# $Id: Makefile 473 2009-09-02 11:20:06Z valenok $

PROG=	mongoose

all:
	@echo "make (linux|bsd|solaris|mac|windows|mingw)"

# Possible COPT values: (in brackets are rough numbers for 'gcc -O2' on i386)
# -DHAVE_MD5		- use system md5 library (-2kb)
# -DNDEBUG		- strip off all debug code (-5kb)
# -DDEBUG		- build debug version (very noisy) (+7kb)
# -DNO_CGI		- disable CGI support (-5kb)
# -DNO_SSL		- disable SSL functionality (-2kb)
# -DCONFIG_FILE=\"file\" - use `file' as the default config file
# -DHAVE_STRTOUI64	- use system strtoui64() function for strtoull()
# -DSSL_LIB=\"libssl.so.<version>\" - use system versioned SSL shared object
# -DCRYPTO_LIB=\"libcrypto.so.<version>\" - use system versioned CRYPTO so


##########################################################################
###                 UNIX build: linux, bsd, mac, rtems
##########################################################################

CFLAGS=		-g -W -Wall -std=c99 -pedantic -O2 $(COPT)
MAC_SHARED=	-flat_namespace -bundle -undefined suppress
LINFLAGS=	-ldl -pthread $(CFLAGS)
LIB=		_$(PROG).so

# Make sure that the compiler flags come last in the compilation string.
# If not so, this can break some on some Linux distros which use
# "-Wl,--as-needed" turned on by default  in cc command.
# Also, this is turned in many other distros in static linkage builds.
linux:
	cd ../.. ; $(CC) $(LINFLAGS) `pkg-config --cflags --libs lua5.1` bindings/lua/luamongoose.c -shared -fPIC -fpic -s -o $(PROG).so $(LIB)

bsd:
#TODO

mac:
#TODO

solaris:
#TODO


##########################################################################
###            WINDOWS build: Using Visual Studio or Mingw
##########################################################################

# Using Visual Studio 6.0. To build Mongoose:
#  o  Set VC variable below to where VS 6.0 is installed on your system
#  o  Run "PATH_TO_VC6\bin\nmake windows"

VC=			"C:\Program Files (x86)\Microsoft Visual Studio 10.0\VC"
#VC=		d:\vc2010\vc
#VC=		d:\vc6
SDK=		"C:\Program Files\Microsoft SDKs\Windows\v6.0A"
#SDK=		d:\sdk\v7.1
#WINDBG=	/Zi /DDEBUG /Od /DDEBUG
LUA=	"C:\Lua\5.1"
WINDBG=		/DNDEBUG /Os
WINFLAGS=	/MT /TC /nologo /W4 $(WINDBG) /I $(VC)/include \
		/I $(SDK)\include /I $(LUA)/include /link /incremental:no \
		/libpath:$(VC)\lib /libpath:$(SDK)/lib ws2_32.lib

windows:
	$(VC)\bin\cl.exe luamongoose.c $(WINFLAGS) \
		/DLL /out:..\..\$(PROG).dll /libpath:$(LUA)/lib lua51.lib \
		..\..\_mongoose.lib

# Build for Windows under MinGW
#MINGWDBG= -DDEBUG -O0
MINGWDBG= -DNDEBUG -Os
MINGWOPT= -W -Wall -mthreads -Wl,--subsystem,console $(MINGWDBG) -DHAVE_STDINT
mingw:
#TODO


##########################################################################
###            Manuals, cleanup, test, release
##########################################################################

clean:

