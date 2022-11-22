local fltkTopLevelKeywords = {}

local luaKeyWords =
{"copcall", "collectgarbage", "math", "module", "xpcall", "next", "assert", "load", "select",
"loadfile", "_G", "unpack", "setmetatable", "getmetatable", "rawset", "rawget", "dofile",
"os", "debug", "table", "ipairs", "print", "arg", "pcall", "getfenv", "io", "add", "package",
"require", "rawequal", "setfenv", "pairs", "string", "lua_bindtypes", "type", "coxpcall",
"gcinfo", "_VERSION", "tostring", "coroutine", "loadstring", "error", "tonumber", "newproxy"}

local murgaLuaKeyWords =
{"getUserData", "setMenu", "getMenu", "murgaLua_Level", "_enableMurgaLuaLite",
"bind_lua_addtovtable", "murgaLua_ExePath", "murgaLua_Version", "murgaLua_About",
"_enableRingsStable", "_enableMurgaLuaFull", "_enableMurgaLuaCore", "lua_bindtypes"}

function table.contains(table, element)
  for _, value in pairs(table) do
    if value == element then
      return true
    end
  end
  return false
end

local function createApiFile(api_name, api_table)
  print(api_name)
  io.flush()
  for memberName, memberData in pairs(api_table) do
    print (api_name .. " . " .. tostring(memberName))
  end
end

for api_name, api_table in pairs(_G) do

  -- Fltk strings
  if (string.find(api_name, "__")) then
--    print(api_name)
  elseif (string.find(api_name, "Fl_")) then
    table.insert(fltkTopLevelKeywords, api_name)
  elseif (string.find(api_name, "FL_")) then
    table.insert(fltkTopLevelKeywords, api_name)
  elseif (table.contains(luaKeyWords, api_name) or table.contains(murgaLuaKeyWords, api_name)) then
	--
  else
	createApiFile(api_name, api_table)
  end
end

for _, value in pairs(fltkTopLevelKeywords) do
  print(value)
end


--[[
fann
core
lpeg
logging
fltk
lfs
md5
cosmo
re
date
proAudio
bit
zlib
random
sqlite3
ltn12
socket
newproxy
murgaLua
mime
alien
Fl
copas
lzo
rings
crypto
--]]
