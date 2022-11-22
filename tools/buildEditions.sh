# Get a sensible OS name

fileExt=""

os=`uname -s`
case "$os" in
    MINGW32*) fileExt=".exe"
esac

make clean

export BUILD_TYPE="MURGALUA_CORE"; make $1; cp bin/murgaLua${fileExt} bin/murgaLua_core${fileExt}
export BUILD_TYPE="MURGALUA_LITE"; make $1; cp bin/murgaLua${fileExt} bin/murgaLua_lite${fileExt}
export BUILD_TYPE="MURGALUA_FULL"; make $1; cp bin/murgaLua${fileExt} bin/murgaLua_full${fileExt}

rm bin/file2c${fileExt}
rm bin/murgaLua${fileExt}

make clean

