gcc ../tools/file2c.c -o ../bin/file2c

#WEIRD luac behaviour
cd ../src
LUAC_CMD="luac -s -o"

echo "const char luaSocketCode_socket[] = { " > socketLua-temp.h
sed "s/require(\"socket.core\")/require(\"socket\")/g" ../3rd-party/luasocket-2.0.2-MOD/src/socket.lua > socketLua-temp.lua
${LUAC_CMD} luaBytecode.out socketLua-temp.lua
cat luaBytecode.out | ../bin/file2c -x >> socketLua-temp.h
#echo -n ",00" >> socketLua-temp.h
echo " }; " >> socketLua-temp.h

echo "const char luaSocketCode_mime[] = { " >> socketLua-temp.h
sed "s/require(\"mime.core\")/require(\"mime\")/g" ../3rd-party/luasocket-2.0.2-MOD/src/mime.lua > socketLua-temp.lua
${LUAC_CMD} luaBytecode.out socketLua-temp.lua
cat luaBytecode.out | ../bin/file2c -x >> socketLua-temp.h
#echo -n ",00" >> socketLua-temp.h
echo " }; " >> socketLua-temp.h

echo "const char luaSocketCode_ltn12[] = { " >> socketLua-temp.h
${LUAC_CMD} luaBytecode.out ../3rd-party/luasocket-2.0.2-MOD/src/ltn12.lua
cat luaBytecode.out | ../bin/file2c -x >> socketLua-temp.h
#echo -n ",00" >> socketLua-temp.h
echo " }; " >> socketLua-temp.h

echo "const char luaSocketCode_tp[] = { " >> socketLua-temp.h
${LUAC_CMD} luaBytecode.out ../3rd-party/luasocket-2.0.2-MOD/src/tp.lua
cat luaBytecode.out | ../bin/file2c -x >> socketLua-temp.h
#echo -n ",00" >> socketLua-temp.h
echo " }; " >> socketLua-temp.h

echo "const char luaSocketCode_url[] = { " >> socketLua-temp.h
${LUAC_CMD} luaBytecode.out ../3rd-party/luasocket-2.0.2-MOD/src/url.lua
cat luaBytecode.out | ../bin/file2c -x >> socketLua-temp.h
#echo -n ",00" >> socketLua-temp.h
echo " }; " >> socketLua-temp.h

echo "const char luaSocketCode_ftp[] = { " >> socketLua-temp.h
${LUAC_CMD} luaBytecode.out ../3rd-party/luasocket-2.0.2-MOD/src/ftp.lua
cat luaBytecode.out | ../bin/file2c -x >> socketLua-temp.h
#echo -n ",00" >> socketLua-temp.h
echo " }; " >> socketLua-temp.h

echo "const char luaSocketCode_http[] = { " >> socketLua-temp.h
${LUAC_CMD} luaBytecode.out ../3rd-party/luasocket-2.0.2-MOD/src/http.lua
cat luaBytecode.out | ../bin/file2c -x >> socketLua-temp.h
#echo -n ",00" >> socketLua-temp.h
echo " }; " >> socketLua-temp.h

echo "const char luaSocketCode_smtp[] = { " >> socketLua-temp.h
${LUAC_CMD} luaBytecode.out ../3rd-party/luasocket-2.0.2-MOD/src/smtp.lua
cat luaBytecode.out | ../bin/file2c -x >> socketLua-temp.h
#echo -n ",00" >> socketLua-temp.h
echo " }; " >> socketLua-temp.h

rm socketLua-temp.lua
rm luaBytecode.out
