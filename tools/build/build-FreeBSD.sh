echo "======================================================================"
echo "# Doing setup                                                        #"
echo "======================================================================"

#chmod +x tools/upx
export CC=gcc
export CXX=g++

export INSTALL_TOP=/usr/local
export CONFIGURE_FLAGS="--prefix=${INSTALL_TOP}"

export PATH=${PATH}:${INSTALL_TOP}/bin

export MAKE_TARGET=unix
export LUA_MTARGET=bsd

export BIN_DIR="FreeBSD"
export BIN_EXT=""

export C_INCLUDE_PATH=${INSTALL_TOP}/include
export LD_LIBRARY_PATH=${INSTALL_TOP}/lib
#export CPLUS_INCLUDE_PATH=
export CFLAGS="-O2 -fno-exceptions"

export FLTK_PARAMS="--enable-xft"

chmod +x tools/build/makeMurgaLua.sh
sh tools/build/makeMurgaLua.sh

sh tools/buildEditions.sh ${MAKE_TARGET}

mv bin/murgaLua_full bin/${BIN_DIR}/murgaLua
mv bin/murgaLua_* bin/${BIN_DIR}/core-lite
