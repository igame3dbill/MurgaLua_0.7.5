gcc ../tools/file2c.c -o ../bin/file2c

#WEIRD luac behaviour
cd ../src
LUAC_CMD="luac -s -o"

#Geta sensible OS name
os=`uname -s`
case "$os" in
    MINGW32*) os="Windows"
esac

if [ ! "${MURGALUA_OS}" ]; then
	MURGALUA_OS=$1
fi

echo "Build  OS is : "${os}/${1}/${2}
echo "Target OS is : "$MURGALUA_OS

cp murgaLuaLib.lua murgaLuaLib-temp.lua
echo "function getBuildProperties () return {buildOs=\"${os}\", makeTarget=\"${1}\", buildType=\"${2}\"} end" >> murgaLuaLib-temp.lua
echo "function getHostOsName () return \"$MURGALUA_OS\" end" >> murgaLuaLib-temp.lua

echo "const char murgaLuaLib_lua[] = { " > murgaLuaLib-temp.h
${LUAC_CMD} luaBytecode.out murgaLuaLib-temp.lua
cat luaBytecode.out | ../bin/file2c -x >> murgaLuaLib-temp.h
#echo -n ",00" >> murgaLuaLib-temp.h
echo " }; " >> murgaLuaLib-temp.h

echo "#ifndef MURGALUA_CORE" >> murgaLuaLib-temp.h

echo "const char murgaLuaLib_fltk[] = { " >> murgaLuaLib-temp.h
${LUAC_CMD} luaBytecode.out murgaLuaFltk.lua
cat luaBytecode.out | ../bin/file2c -x >> murgaLuaLib-temp.h
#echo -n ",00" >> murgaLuaLib-temp.h
echo " }; " >> murgaLuaLib-temp.h

echo "#endif" >> murgaLuaLib-temp.h

echo "const char murgaLuaLib_murgaLuaDebug[] = { " >> murgaLuaLib-temp.h
${LUAC_CMD} luaBytecode.out murgaLuaDebug.lua
cat luaBytecode.out | ../bin/file2c -x >> murgaLuaLib-temp.h
#echo -n ",00" >> murgaLuaLib-temp.h
echo " }; " >> murgaLuaLib-temp.h

echo "const char murgaLuaLib_murgaLua_serialize[] = { " >> murgaLuaLib-temp.h
${LUAC_CMD} luaBytecode.out ../3rd-party/serialize-mod.lua
cat luaBytecode.out | ../bin/file2c -x >> murgaLuaLib-temp.h
#echo -n ",00" >> murgaLuaLib-temp.h
echo " }; " >> murgaLuaLib-temp.h

echo "const char murgaLuaLib_alien[] = { " >> murgaLuaLib-temp.h
sed "s/local core = require \"alien.core\"/core = alien.core/g" ../3rd-party/alien-0.4.1-MOD/src/alien.lua > murgaLuaLib-temp.lua
${LUAC_CMD} luaBytecode.out murgaLuaLib-temp.lua
cat luaBytecode.out | ../bin/file2c -x >> murgaLuaLib-temp.h
#echo -n ",00" >> murgaLuaLib-temp.h
echo " }; " >> murgaLuaLib-temp.h


echo "const char murgaLuaLib_coxpcall[] = { " >> murgaLuaLib-temp.h
${LUAC_CMD} luaBytecode.out ../3rd-party/coxpcall-1.13.0/src/coxpcall.lua
cat luaBytecode.out | ../bin/file2c -x >> murgaLuaLib-temp.h
#echo -n ",00" >> murgaLuaLib-temp.h
echo " }; " >> murgaLuaLib-temp.h

echo "const char murgaLuaLib_copas[] = { " >> murgaLuaLib-temp.h
sed "s/require\"coxpcall\"//g" ../3rd-party/copas-1.1.4/src/copas/copas.lua > murgaLuaLib-temp.lua
${LUAC_CMD} luaBytecode.out murgaLuaLib-temp.lua
cat luaBytecode.out | ../bin/file2c -x >> murgaLuaLib-temp.h
#echo -n ",00" >> murgaLuaLib-temp.h
echo " }; " >> murgaLuaLib-temp.h

echo "const char murgaLuaLib_logging[] = { " >> murgaLuaLib-temp.h
${LUAC_CMD} luaBytecode.out ../3rd-party/lualogging-1.1.4-MOD/src/logging/logging.lua
cat luaBytecode.out | ../bin/file2c -x >> murgaLuaLib-temp.h
#echo -n ",00" >> murgaLuaLib-temp.h
echo " }; " >> murgaLuaLib-temp.h

echo "const char murgaLuaLib_loggingConsole[] = { " >> murgaLuaLib-temp.h
sed "s/require\"logging\"//g" ../3rd-party/lualogging-1.1.4-MOD/src/logging/console.lua > murgaLuaLib-temp.lua
${LUAC_CMD} luaBytecode.out murgaLuaLib-temp.lua
cat luaBytecode.out | ../bin/file2c -x >> murgaLuaLib-temp.h
#echo -n ",00" >> murgaLuaLib-temp.h
echo " }; " >> murgaLuaLib-temp.h

echo "const char murgaLuaLib_loggingFile[] = { " >> murgaLuaLib-temp.h
sed "s/require\"logging\"//g" ../3rd-party/lualogging-1.1.4-MOD/src/logging/file.lua > murgaLuaLib-temp.lua
${LUAC_CMD} luaBytecode.out murgaLuaLib-temp.lua
cat luaBytecode.out | ../bin/file2c -x >> murgaLuaLib-temp.h
#echo -n ",00" >> murgaLuaLib-temp.h
echo " }; " >> murgaLuaLib-temp.h

echo "const char murgaLuaLib_loggingSocket[] = { " >> murgaLuaLib-temp.h
sed "s/require\"logging\"//g" ../3rd-party/lualogging-1.1.4-MOD/src/logging/socket.lua > murgaLuaLib-temp.lua
${LUAC_CMD} luaBytecode.out murgaLuaLib-temp.lua
cat luaBytecode.out | ../bin/file2c -x >> murgaLuaLib-temp.h
#echo -n ",00" >> murgaLuaLib-temp.h
echo " }; " >> murgaLuaLib-temp.h

echo "const char murgaLuaLib_loggingEmail[] = { " >> murgaLuaLib-temp.h
sed "s/require\"logging\"//g" ../3rd-party/lualogging-1.1.4-MOD/src/logging/email.lua > murgaLuaLib-temp.lua
${LUAC_CMD} luaBytecode.out murgaLuaLib-temp.lua
cat luaBytecode.out | ../bin/file2c -x >> murgaLuaLib-temp.h
#echo -n ",00" >> murgaLuaLib-temp.h
echo " }; " >> murgaLuaLib-temp.h

echo "const char murgaLuaLib_Stable[] = { " >> murgaLuaLib-temp.h
${LUAC_CMD} luaBytecode.out ../3rd-party/rings-1.2.2-MOD/src/stable.lua
cat luaBytecode.out | ../bin/file2c -x >> murgaLuaLib-temp.h
#echo -n ",00" >> murgaLuaLib-temp.h
echo " }; " >> murgaLuaLib-temp.h

echo "#ifndef MURGALUA_LITE" >> murgaLuaLib-temp.h

echo "const char murgaLuaLib_IniLazy[] = { " >> murgaLuaLib-temp.h
${LUAC_CMD} luaBytecode.out ../3rd-party/inilazy-1.0.4beta/inilazy.lua
cat luaBytecode.out | ../bin/file2c -x >> murgaLuaLib-temp.h
#echo -n ",00" >> murgaLuaLib-temp.h
echo " }; " >> murgaLuaLib-temp.h

echo "const char murgaLuaLib_md5[] = { " >> murgaLuaLib-temp.h
sed "s/require\"md5.core\"/require\"md5\"/g" ../3rd-party/md5-1.1.2/src/md5.lua > murgaLuaLib-temp.lua
${LUAC_CMD} luaBytecode.out murgaLuaLib-temp.lua
cat luaBytecode.out | ../bin/file2c -x >> murgaLuaLib-temp.h
#echo -n ",00" >> murgaLuaLib-temp.h
echo " }; " >> murgaLuaLib-temp.h

echo "const char murgaLuaLib_date[] = { " >> murgaLuaLib-temp.h
${LUAC_CMD} luaBytecode.out ../3rd-party/date/date.lua
cat luaBytecode.out | ../bin/file2c -x >> murgaLuaLib-temp.h
#echo -n ",00" >> murgaLuaLib-temp.h
echo " }; " >> murgaLuaLib-temp.h

echo "const char murgaLuaLib_re[] = { " >> murgaLuaLib-temp.h
${LUAC_CMD} luaBytecode.out ../3rd-party/lpeg-0.9/re.lua
cat luaBytecode.out | ../bin/file2c -x >> murgaLuaLib-temp.h
#echo -n ",00" >> murgaLuaLib-temp.h
echo " }; " >> murgaLuaLib-temp.h

echo "const char murgaLuaLib_cosmo_grammer[] = { " >> murgaLuaLib-temp.h
sed "s/module(\.\.\./module(\"cosmo.grammar\"/g" ../3rd-party/cosmo-8.04.14/src/cosmo/grammar.lua > murgaLuaLib-temp.lua
${LUAC_CMD} luaBytecode.out murgaLuaLib-temp.lua
cat luaBytecode.out | ../bin/file2c -x >> murgaLuaLib-temp.h
#echo -n ",00" >> murgaLuaLib-temp.h
echo " }; " >> murgaLuaLib-temp.h

echo "const char murgaLuaLib_cosmo_fill[] = { " >> murgaLuaLib-temp.h
sed "s/module(\.\.\./module(\"cosmo.fill\"/g" ../3rd-party/cosmo-8.04.14/src/cosmo/fill.lua > murgaLuaLib-temp.lua
${LUAC_CMD} luaBytecode.out murgaLuaLib-temp.lua
cat luaBytecode.out | ../bin/file2c -x >> murgaLuaLib-temp.h
#echo -n ",00" >> murgaLuaLib-temp.h
echo " }; " >> murgaLuaLib-temp.h

echo "const char murgaLuaLib_cosmo[] = { " >> murgaLuaLib-temp.h
sed "s/module(\.\.\./module(\"cosmo\"/g" ../3rd-party/cosmo-8.04.14/src/cosmo.lua > murgaLuaLib-temp.lua
${LUAC_CMD} luaBytecode.out murgaLuaLib-temp.lua
cat luaBytecode.out | ../bin/file2c -x >> murgaLuaLib-temp.h
#echo -n ",00" >> murgaLuaLib-temp.h
echo " }; " >> murgaLuaLib-temp.h

echo "#endif" >> murgaLuaLib-temp.h

rm murgaLuaLib-temp.lua
rm luaBytecode.out
