#!/bin/sh

/bin/murgaLua -e "murgaLua.compileMurgaLua (\"/ig3d_mac_xcode/Data/Fluid/SpellingList/SpellingList.lua\", \"/bin/murgaLua\", \"/ig3d_mac_xcode/Data/Fluid/SpellingList/SpellingList\")"
/bin/murgaLua -e "murgaLua.decompileMurgaLua (\"/ig3d_mac_xcode/Data/Fluid/SpellingList/SpellingList\", \"/ig3d_mac_xcode/Data/Fluid/SpellingList/out.lua\")"
chmod +x /ig3d_mac_xcode/Data/Fluid/SpellingList/SpellingList
