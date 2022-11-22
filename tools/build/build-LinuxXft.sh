echo "======================================================================"
echo "# Doing setup                                                        #"
echo "======================================================================"

export CC=gcc

export INSTALL_TOP=/usr/local
export CONFIGURE_FLAGS="--prefix=${INSTALL_TOP} --disable-debug --enable-no_exceptions --enable-no_rtti"

export C_INCLUDE_PATH=${INSTALL_TOP}/include
export CFLAGS="-I/usr/local/include -DLUA_USE_LINUX -DLUA_USE_APICHECK -O2 -fno-exceptions -fno-strict-aliasing -fno-builtin-malloc -fno-builtin-calloc -fno-builtin-realloc -fno-builtin-free"
export LDFLAGS="-Wl,--sort-common -Wl,--sort-section,alignment -Wl,--gc-sections"

export FLTK_PARAMS="--enable-xft"

export MAKE_TARGET=linux
export LUA_MTARGET=linux

export BIN_DIR="Linux"
export BIN_EXT=""

# Mostly specific
export STRIP_CMD="strip -R .comment -R .note -R .note.ABI-tag -R .gnu.version"

chmod +x tools/upx
ln -s `gcc --print-file-name libstdc++.a`

export PATH=${PATH}:${INSTALL_TOP}/bin

chmod +x tools/build/makeMurgaLua.sh
sh tools/build/makeMurgaLua.sh
