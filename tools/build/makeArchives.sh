relNum="7.0"

chmod +x tools/upx*
chmod +x tools/*.sh

chmod +x bin/Windows/*
chmod +x bin/Linux/*
chmod +x bin/MacOs-Intel/*

./tools/upx --lzma --best bin/MacOs-Intel/*

cd ..
rm -r website
mkdir website
cp -r murgaLua/doc/* website
cp -r files website

echo "======================================================================"
echo "# Creating full archives                                            #"
echo "======================================================================"
tar -zcvf website/snapshot/murgaLua-0.${relNum}.tar.gz murgaLua

echo "======================================================================"
echo "# Creating source archives                                           #"
echo "======================================================================"
mv murgaLua/bin bin
tar -zcvf website/snapshot/murgaLua-0.${relNum}-src.tar.gz murgaLua
mv bin murgaLua

echo "======================================================================"
echo "# Creating Windows archives                                          #"
echo "======================================================================"
cd murgaLua/bin/Windows
mv ../../examples .
tar -zcvf ../../../website/snapshot/murgaLua-0.${relNum}-Win32.tar.gz examples fluid.exe  luacom  murgaLua.exe
tar -zcvf ../../../website/snapshot/murgaLua-0.${relNum}-Win32-Patcher.tar.gz no\ console\ patch.*

echo "======================================================================"
echo "# Creating MacOS archives                                            #"
echo "======================================================================"
cd ../MacOs-Intel
mv ../Windows/examples .
tar -zcvf ../../../website/snapshot/murgaLua-0.${relNum}-MacOs.tar.gz examples fluid murgaLua

echo "======================================================================"
echo "# Creating main Linux archive                                        #"
echo "======================================================================"
cd ../Linux
mv ../MacOs-Intel/examples .
tar -zcvf ../../../website/snapshot/murgaLua-0.${relNum}-Linux.tar.gz examples fluid murgaLua

echo "======================================================================"
echo "# creating other Linux archives                                      #"
echo "======================================================================"
cp fluid otherBuilds
cd otherBuilds
mv ../examples .
tar -zcvf ../../../../website/snapshot/murgaLua-0.${relNum}-Linux-noXft.tar.gz examples fluid_nonXft murgaLua_nonXft
tar -zcvf ../../../../website/snapshot/murgaLua-0.${relNum}-Linux-Dynamic.tar.gz examples fluid murgaLua_Dynamic
tar -zcvf ../../../../website/snapshot/murgaLua-0.${relNum}-Linux-Dynamic-noXft.tar.gz examples fluid_nonXft murgaLua_Dynamic_nonXft
rm fluid
mv examples ../../..

echo "======================================================================"
echo "# All done !!                                                        #"
echo "======================================================================"
