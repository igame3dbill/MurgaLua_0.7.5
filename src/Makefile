#
# Makefile - murgaLua Makefile
#
# Copyright (C) 2006-20012 John Murga
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the :
# 
#   Free Software Foundation, Inc.
#   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#

PLAT    = none
PLATS   = linux linuxStatic windows macos unix
INSTALL_TOP?= /usr/local
BUILD_TYPE?= MURGALUA_FULL
STRIP_CMD?= strip
GCC_STRIP?=

#linux_LINK_OPT       = -Wl,--gc-sections -lm -ldl -L.. -static-libgcc -lsqlite3 -lreadline -lhistory -lncurses
linux_LINK_OPT       = -Wl,--gc-sections -lm -ldl -lreadline -lhistory -lncurses -lasound $(INSTALL_TOP)/lib/libsqlite3.a $(INSTALL_TOP)/lib/libcrypto.a $(INSTALL_TOP)/lib/libdoublefann.a
linuxStatic_LINK_OPT = -Wl,--gc-sections -ldl -lpthread -static-libgcc -L.. $(INSTALL_TOP)/lib/libsqlite3.a $(INSTALL_TOP)/lib/libcrypto.a $(INSTALL_TOP)/lib/libdoublefann.a
unix_LINK_OPT        = --gc-sections -lpthread $(INSTALL_TOP)/lib/libsqlite3.a $(INSTALL_TOP)/lib/libcrypto.a $(INSTALL_TOP)/lib/libdoublefann.a
windows_LINK_OPT     = -Wl,--gc-sections $(INSTALL_TOP)/lib/libsqlite3.a $(INSTALL_TOP)/lib/libcrypto.a $(INSTALL_TOP)/lib/libdoublefann.a -lm -lwinmm -mconsole -ldsound
macos_LINK_OPT       = $(INSTALL_TOP)/lib/libsqlite3.a $(INSTALL_TOP)/lib/libcrypto.a $(INSTALL_TOP)/lib/libdoublefann.a -lm -lreadline -framework CoreAudio

#-D__LINUX_OSS__
linux_CXX_OPT        = -D$(BUILD_TYPE) -DTIXML_USE_STL -DLINUX -DLUA_USE_LINUX -D__LINUX_ALSA__ -DSQLITE_HAS_CODEC
linuxStatic_CXX_OPT  = -D$(BUILD_TYPE) -DTIXML_USE_STL -DLINUX -D__LINUX_OSS__ -DSQLITE_HAS_CODEC
unix_CXX_OPT         = -D$(BUILD_TYPE) -DTIXML_USE_STL -DLINUX -D__LINUX_OSS__ -DSQLITE_HAS_CODEC
windows_CXX_OPT      = -D$(BUILD_TYPE) -DTIXML_USE_STL -DWINDOWS -DWIN32 -D__WINDOWS_DS__ -DSQLITE_HAS_CODEC
macos_CXX_OPT        = -D$(BUILD_TYPE) -DTIXML_USE_STL -DMACOS -DDARWIN -DLUA_USE_LINUX -D__MACOSX_CORE__ -DSQLITE_HAS_CODEC

linuxOBJ        = ../3rd-party/luasocket-2.0.2-MOD/src/usocket.o
linuxStaticOBJ  = ../3rd-party/luasocket-2.0.2-MOD/src/usocket.o
unixOBJ         = ../3rd-party/luasocket-2.0.2-MOD/src/usocket.o
windowsOBJ      = ../3rd-party/luasocket-2.0.2-MOD/src/wsocket.o
macosOBJ        = ../3rd-party/luasocket-2.0.2-MOD/src/usocket.o

linuxEXT        = 
linuxStaticEXT  = 
unixEXT         = 
windowsEXT      = .exe
macosEXT        = 

linuxPACK       = ../tools/upx --lzma --best
linuxStaticPACK = ../tools/upx --lzma --best
unixPACK        = @echo "You can try packing with UPX on Windows or Linux"
windowsPACK     = ../tools/upx.exe --lzma --best
macosPACK       = @echo "Pack with UPX on Windows or Linux"

TARGET       = ../bin/murgaLua
LUA_CXXFLAGS = -DLUA

MEM_FLAGS   = -DLUA_USE_APICHECK -fno-builtin-malloc -fno-builtin-calloc -fno-builtin-realloc -fno-builtin-free
CFLAGS  	= -I/usr/local/include -Os -fno-exceptions -fno-strict-aliasing $(MEM_FLAGS) `fltk-config --use-images --cxxflags` $(LUA_CXXFLAGS) $($(PLAT)_CXX_OPT)
CXXFLAGS	= -fpermissive -fno-rtti $(CFLAGS)
MY_LDFLAGS	= `fltk-config --use-images --ldstaticflags` $(INSTALL_TOP)/lib/liblua.a $(INSTALL_TOP)/lib/libffi.a $($(PLAT)_LINK_OPT)


CPP_OBJS_MURGALUA_BASIC = \
	murgaLua.o \
	murgaLuaLib.o \
	../3rd-party/tinyxml/tinyxml.o \
	../3rd-party/tinyxml/tinyxmlparser.o \
	../3rd-party/tinyxml/tinyxmlerror.o \
	../3rd-party/tinyxml/tinystr.o \
	$($(PLAT)OBJ)


C_OBJS_MURGALUA_BASIC = \
	../3rd-party/luasocket-2.0.2-MOD/src/auxiliar.o \
	../3rd-party/luasocket-2.0.2-MOD/src/except.o \
	../3rd-party/luasocket-2.0.2-MOD/src/io.o \
	../3rd-party/luasocket-2.0.2-MOD/src/mime.o \
	../3rd-party/luasocket-2.0.2-MOD/src/select.o \
	../3rd-party/luasocket-2.0.2-MOD/src/timeout.o \
	../3rd-party/luasocket-2.0.2-MOD/src/udp.o \
	../3rd-party/luasocket-2.0.2-MOD/src/buffer.o \
	../3rd-party/luasocket-2.0.2-MOD/src/inet.o \
	../3rd-party/luasocket-2.0.2-MOD/src/luasocket.o \
	../3rd-party/luasocket-2.0.2-MOD/src/options.o \
	../3rd-party/luasocket-2.0.2-MOD/src/tcp.o \
	../3rd-party/luaLZO/minilzo.o \
	../3rd-party/luasys-MOD/src/luasys.o \
	../3rd-party/luasys-MOD/src/mem/sys_mem.o \
	../3rd-party/rings-1.2.2-MOD/src/rings.o \
	../3rd-party/alien-0.4.1-MOD/src/alien/core.o \
	../3rd-party/alien-0.4.1-MOD/src/alien/struct.o \
	../3rd-party/luafilesystem-1.4.2/src/lfs.o \
	../3rd-party/lua-iostring-MOD/iostring.o \
	../3rd-party/luaLZO/luaLZO.o

CPP_OBJS_MURGALUA_BASIC_LITE = \
	bind-fltk-ext.o \
	Fl_murgaLuaTimer.o \
	Fl_murgaLuaOffScreen.o \
	../3rd-party/proteaAudio_MOD/stb_vorbis.o \
	../3rd-party/proteaAudio_MOD/proAudio.o \
	../3rd-party/proteaAudio_MOD/proAudioRt_lua.o


CPP_OBJS_MURGALUA_LITE = $(CPP_OBJS_MURGALUA_BASIC) $(CPP_OBJS_MURGALUA_BASIC_LITE)

C_OBJS_MURGALUA_LITE =  $(C_OBJS_MURGALUA_BASIC)

EXT_OBJS_MURGALUA_LITE = ../3rd-party/proteaAudio_MOD/proAudioRt.o ../3rd-party/proteaAudio_MOD/rtaudio/RtAudio.o


CPP_OBJS_MURGALUA_CORE = $(CPP_OBJS_MURGALUA_BASIC)

C_OBJS_MURGALUA_CORE = $(C_OBJS_MURGALUA_BASIC) \
	../3rd-party/slncrypto-1.1/slncrypt.o \
	../3rd-party/md5-1.1.2/src/md5.o \
	../3rd-party/md5-1.1.2/src/md5lib.o \
	../3rd-party/lzlib-0.4-work2/lzlib.o \
	../3rd-party/random-MOD/lrandom.o \
	../3rd-party/lpeg-0.9/lpeg.o \
	../3rd-party/LuaBitOp-1.0.1/bit.o \
	../3rd-party/lfann-mainline/src/interface.o \
	../3rd-party/lsqlite3-MOD/lsqlite3.o \
	../3rd-party/jmaygarden-lua/mongoose.o \
	../3rd-party/jmaygarden-lua/bindings/lua/luamongoose.o \
	../3rd-party/lua-cjson-1.0.4/strbuf.o \
	../3rd-party/lua-cjson-1.0.4/lua_cjson.o

EXT_OBJS_MURGALUA_CORE =


CPP_OBJS_MURGALUA_FULL = $(CPP_OBJS_MURGALUA_BASIC_LITE) $(CPP_OBJS_MURGALUA_CORE)

C_OBJS_MURGALUA_FULL   = $(C_OBJS_MURGALUA_CORE)

EXT_OBJS_MURGALUA_FULL = $(EXT_OBJS_MURGALUA_LITE) 


AR     ?= ar
RANLIB ?= ranlib
CC     ?= gcc
CXX    ?= g++

none:
	@echo ""
	@echo "Please do"
	@echo "   make PLATFORM"
	@echo "where PLATFORM is one of these:"
	@echo "   $(PLATS)"
	@echo ""

$(PLATS) :
	rm -f murgaLua.o
	sh ../tools/embedLuaSocket.sh
	sh ../tools/embedMurgaLuaLib.sh $@ $(BUILD_TYPE)
	$(MAKE) $(TARGET) PLAT=$@
	sleep 1 # Hack to get around issues with file scanners under Windows
	$(STRIP_CMD) $(TARGET)$($@EXT)
	$($@PACK) $(TARGET)$($@EXT)
	
	
all : $(PLAT)

../3rd-party/proteaAudio_MOD/proAudioRt.o :
	$(CXX) $(GCC_STRIP) $(CXXFLAGS)  -fexceptions -c $< ../3rd-party/proteaAudio_MOD/proAudioRt.cpp
	mv proAudioRt.o ../3rd-party/proteaAudio_MOD/proAudioRt.o

../3rd-party/proteaAudio_MOD/rtaudio/RtAudio.o :
	$(CXX) $(GCC_STRIP) $(CXXFLAGS)  -fexceptions -c $< -I../3rd-party/proteaAudio_MOD/rtaudio/include ../3rd-party/proteaAudio_MOD/rtaudio/RtAudio.cpp
	mv RtAudio.o ../3rd-party/proteaAudio_MOD/rtaudio/RtAudio.o

bind-fltk-ext.o : bind-fltk.cxx

$(TARGET): $(CPP_OBJS_$(BUILD_TYPE)) $(C_OBJS_$(BUILD_TYPE)) $(EXT_OBJS_$(BUILD_TYPE))
	@echo [compiling $<]
	$(CXX) $(GCC_STRIP) $(CXXFLAGS) $(CPP_OBJS_$(BUILD_TYPE)) $(C_OBJS_$(BUILD_TYPE)) $(EXT_OBJS_$(BUILD_TYPE)) $(LDFLAGS) $(MY_LDFLAGS) -o $@

.PHONY : clean
clean :
	@echo CLEANING - Just in case
	rm -f $(CPP_OBJS_MURGALUA_FULL) $(C_OBJS_MURGALUA_FULL) $(EXT_OBJS_MURGALUA_FULL) $(linuxOBJ) $(windowsOBJ) socketLua-temp.h murgaLuaLib-temp.h > /dev/null

%.o : %.cxx
	@echo [compiling $<]
	$(CXX) $(GCC_STRIP) $(CXXFLAGS) -c $< -o $@

%.o : %.cpp
	@echo [compiling $<]
	$(CXX) $(GCC_STRIP) $(CXXFLAGS) -c $< -o $@

%.o : %.c
	@echo [compiling $<]
	$(CC) $(GCC_STRIP) $(CFLAGS) -c $< -o $@

