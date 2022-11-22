
#
# Generic build script, for use by all platforms
#

mkdir bin/${BIN_DIR} > /dev/null

mkdir ${INSTALL_TOP} > /dev/null
mkdir ${INSTALL_TOP}/lib > /dev/null

# The path to the current scripts location ...
# $(dirname "$0")

echo "======================================================================"
echo "# Building LUA                                                       #"
echo "======================================================================"

cd ..
cd lua-5.*/

patch -N -p0 < ../murgaLua/tools/build/patches/lua_continue.patch
patch -N -p0 < ../murgaLua/tools/build/patches/cross/lua_Make-top.patch Makefile
patch -N -p0 < ../murgaLua/tools/build/patches/cross/lua_Make-src.patch src/Makefile

make clean
make ${LUA_MTARGET}
sleep 4

make install

sleep 4
cd ..

echo "======================================================================"
echo "# Building the Fast Artificial Neural Network Library                #"
echo "======================================================================"
cd fann-2.1.0

./configure ${CONFIGURE_FLAGS}
make clean
make install

sleep 4
cd ..

echo "======================================================================"
echo "# Building OpenSSL lib                                             #"
echo "======================================================================"

cd openssl-0.9.*

make clean
./Configure gcc:" " $CFLAGS no-hw no-dso no-shared no-zlib no-zlib-dynamic no-threads \
no-camellia no-capieng no-cms no-gmp no-jpake no-krb5 no-mdc2 no-rc5 no-rfc3779 no-seed \
no-ssl2 no-ssl3 no-sock no-tls1 no-ec \
no-sha0 no-sha256 no-sha512 no-rc4 no-bf no-md2 no-rc2 \
no-cast no-idea no-smime no-rmd160 no-ripemd \
no-rsa no-dsa no-pem no-engine no-ocsp no-store no-des no-md4 no-dh \
no-err

cd crypto
make depend
make
cd ..

cp libcrypto.a ${INSTALL_TOP}/lib

mkdir ${INSTALL_TOP}/include/openssl

for currentFile in `cat ../murgaLua/tools/build/cryptoIncludes.txt`
do 
    cp $currentFile ${INSTALL_TOP}/include/openssl
done

sleep 4
cd ..

echo "======================================================================"
echo "# Building sqLite                                                    #"
echo "======================================================================"

cd sqlcipher

rm -rf build_dir
mkdir build_dir
cd build_dir

../configure ${CONFIGURE_FLAGS} \
	CFLAGS="${CFLAGS} -DSQLITE_HAS_CODEC -DSQLITE_OMIT_COMPILEOPTION_DIAGS -DSQLITE_OMIT_SHARED_CACHE" \
	LDFLAGS="${INSTALL_TOP}/lib/libcrypto.a" --disable-shared --disable-threadsafe --disable-tcl --disable-amalgamation

# Will need to hack for OpenMoko again ??

make clean
make sqlite3.h
make all
cp sqlite3.h ${INSTALL_TOP}/include/
rm .libs/libsqlite3.a
ar cru .libs/libsqlite3.a *.o
make sqlite3${BIN_EXT}
# If sqlite doesn't build the executable and you want it then
# Copy the gcc line, and put libcrypto.a after libsqlite3.a.
# For Windows add -lgdi32 as it is needed by some of the libcrypto stuff.
cp ./.libs/libsqlite3.a ${INSTALL_TOP}/lib/

sleep 4
cd ../..

echo "======================================================================"
echo "# Building libffi                                                    #"
echo "======================================================================"

cd libffi-3.*

#patch -N -p0 < ../murgaLua/tools/build/patches/cross/ffi-Make.patch Makefile.in

make clean
./configure ${CONFIGURE_FLAGS}
sleep 4

make
sleep 4

make install
cp include/* ${INSTALL_TOP}/include/
cp .libs/libffi.a ${INSTALL_TOP}/lib/

sleep 4
cd ..

echo "======================================================================"
echo "# Building FLTK                                                      #"
echo "======================================================================"

cd fltk-1.1*
patch -N -p0 < ../murgaLua/tools/build/patches/fltk_fluid.patch
chmod +x configure
ls config* | xargs sed -i 's/-mno-cygwin//g'
make clean
./configure ${CONFIGURE_FLAGS} ${FLTK_PARAMS} --disable-threads --disable-gl --enable-localjpeg --enable-localzlib --enable-localpng --with-optim="${CFLAGS} -fno-rtti"
sleep 4
## patch -N -p0 < ../murgaLua/tools/build/patches/cross/fltk-Make.patch
cp -r ../murgaLua/tools/build/patches/fltk_tree/* .
make
sleep 4
make install
cp fluid/fluid${BIN_EXT} ../murgaLua/bin/${BIN_DIR}
make clean
cd ..

echo "======================================================================"
echo "# Building murgaLua                                                  #"
echo "======================================================================"

cd murgaLua/
chmod +x bin/${BIN_DIR}/fluid${BIN_EXT}
strip bin/${BIN_DIR}/fluid${BIN_EXT}
tools/upx${BIN_EXT} --lzma --best bin/${BIN_DIR}/fluid${BIN_EXT}
sleep 4
make clean
make ${MAKE_TARGET}
cd bin
mv murgaLua${BIN_EXT} ${BIN_DIR}
rm file2c${BIN_EXT}
cd ..
make clean

echo "======================================================================"
echo "# All done !!                                                        #"
echo "======================================================================"

