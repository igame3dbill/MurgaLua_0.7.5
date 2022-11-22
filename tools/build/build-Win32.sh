echo "======================================================================"
echo "# Doing setup                                                        #"
echo "======================================================================"

export CC=gcc

export INSTALL_TOP=/usr/local
export CONFIGURE_FLAGS="--prefix=${INSTALL_TOP} --disable-debug --enable-no_exceptions --enable-no_rtti"

export C_INCLUDE_PATH=${INSTALL_TOP}/include
export CFLAGS="-I/usr/local/include -DLUA_USE_APICHECK -Os -fno-exceptions -fno-strict-aliasing -fno-builtin-malloc -fno-builtin-calloc -fno-builtin-realloc -fno-builtin-free"
export LDFLAGS="-Wl,--sort-common -Wl,--sort-section,alignment -Wl,--gc-sections"

export FLTK_PARAMS=""

export MAKE_TARGET=windows
export LUA_MTARGET=mingw

export BIN_DIR="Windows"
export BIN_EXT=".exe"

# Mostly specific
export STRIP_CMD="strip -R .comment -R .note -R .note.ABI-tag -R .gnu.version"
sh tools/build/makeMurgaLua.sh

# Short term mega-hack - Need to fix the Lua build
echo > ${INSTALL_TOP}/bin/lua
echo > ${INSTALL_TOP}/bin/luac

cd ../lua-5.*
make mingw
make install

rm ${INSTALL_TOP}/bin/lua
rm ${INSTALL_TOP}/bin/luac

cd ../murgaLua

sh tools/buildEditions.sh ${MAKE_TARGET}

mv bin/murgaLua_full.exe bin/${BIN_DIR}/murgaLua.exe
mv bin/murgaLua_* bin/${BIN_DIR}/core-lite
