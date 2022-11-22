echo "======================================================================"
echo "# Doing setup                                                        #"
echo "======================================================================"

export CC=gcc

export INSTALL_TOP=/usr/local
export CONFIGURE_FLAGS="--prefix=${INSTALL_TOP} --disable-debug --enable-no_exceptions --enable-no_rtti"

export MAKE_TARGET=macos
export LUA_MTARGET=macosx

export BIN_DIR="MacOs-Intel"
export BIN_EXT=""

export C_INCLUDE_PATH=${INSTALL_TOP}/include
#export CPLUS_INCLUDE_PATH=
#LUA_USE_POSIX
export CFLAGS="-I/usr/local/include -DLUA_USE_APICHECK -DLUA_USE_MACOSX -Os -fno-exceptions -fno-strict-aliasing -fno-builtin-malloc -fno-builtin-calloc -fno-builtin-realloc -fno-builtin-free"
# export CFLAGS="-O2 -fno-exceptions"
# Mnimal LD_FLAGS for MacOS
export LDFLAGS="-L${INSTALL_TOP}/lib"

export FLTK_PARAMS=""

chmod +x tools/build/makeMurgaLua.sh
sh tools/build/makeMurgaLua.sh

sh tools/buildEditions.sh ${MAKE_TARGET}

mv bin/murgaLua_full bin/${BIN_DIR}/murgaLua
mv bin/murgaLua_* bin/${BIN_DIR}/core-lite
