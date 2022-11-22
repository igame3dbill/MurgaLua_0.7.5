echo "======================================================================"
echo "# Doing setup                                                        #"
echo "======================================================================"

# . /usr/local/openmoko/arm/setup-env
chmod +x tools/upx

export INSTALL_TOP=/usr/local/openmoko/arm/arm-angstrom-linux-gnueabi/usr
export CONFIGURE_FLAGS="--host=arm-angstrom-linux-gnueabi --prefix=${INSTALL_TOP}"

export PATH=${PATH}:${INSTALL_TOP}/bin

export MAKE_TARGET=linux
export LUA_MTARGET=linux

export BIN_DIR="OpenMoko"
export BIN_EXT=""

export C_INCLUDE_PATH=${INSTALL_TOP}/include
export CPLUS_INCLUDE_PATH=${INSTALL_TOP}/include/c++/4.1.2/arm-angstrom-linux-gnueabi:${INSTALL_TOP}/include/c++/4.1.2:${INSTALL_TOP}/include/c++/4.1.2/backward

export CFLAGS="-O2 -fno-exceptions"
export GCC_STRIP="-s"

export FLTK_PARAMS="--enable-xft"

chmod +x tools/build/makeMurgaLua.sh
sh tools/build/makeMurgaLua.sh

sh tools/buildEditions.sh ${MAKE_TARGET}

mv bin/murgaLua_full bin/${BIN_DIR}/murgaLua
mv bin/murgaLua_* bin/${BIN_DIR}/core-lite

