-------------------------------------------------------------------------------
-- includes a get function that read any ini file into table
--
-- @author Alexandr Leykin (leykina@gmail.com)
--
-- @Public domain 2008
-- @release $Id: inilazy.lua,v 1.03 2008/04/08 14:49:49 $
-------------------------------------------------------------------------------
--bugfix: thanks smz!

--[[
Function read INI-File:
some.ini
======================
global_KEY=VALUE
[Section1]
s1_KEY=Value
[sect2]
s1_KEY=Value
s1_KEY=Value2
; This Comment
# Comment again
; ...more...
======================
into table:
{
["global_key"] = "VALUE",
Section1={["s1_KEY"]="Value"},
sect2={["s1_KEY"]={"Value","Value2"}}
}

and conversely..
...
--]]

local io = require"io"
local string = require"string"
local table = require"table"
--local print=print
local pairs, ipairs = pairs, ipairs

module ("inilazy")

local function make_err (msg, filename, line_counter, line)
  return string.format ("%s: %s:%d: %s", msg, filename, line_counter, line)
end

function get(filename) --> (ini_table) or (nil,err)
  local f = io.open(filename,'r')
  if not f then return nil, "cannot open file: " .. filename end
  local line_counter=0
  local ini_table = {}
  local section, err
  for fline in f:lines() do
    --set counter for indicate on error
    line_counter=line_counter+1
    --clean for begin and end spaces
    local line = fline:match("^%s*(.-)%s*$")
    --coments
    if not line:match("^[%;#]") and #line > 0 then
      --section
      local sec = line:match("^%[([%w%s]*)%]$")
      if sec then
        section = sec
        if not ini_table[section] then ini_table[section]={} end
      else
        --parse key=value and clean for begin and end spaces
        local key, value = line:match("([^=]*)%=(.*)")
        --check on errors in ini-file
        if not key then
          err = make_err('key/value absent', filename, line_counter, fline)
          break
        end
        --clean for begin and end spaces
        key = key:match("^%s*(%S*)%s*$")
        value = value:match("^%s*(.-)%s*$")
        if not (key and value) then
          err = make_err('bad key or value', filename, line_counter, fline)
          break
        end
        if section then
          if not ini_table[section][key] then ini_table[section][key]={} end
          ini_table[section][key][value] = true
        else
          err = make_err('key/value outside a section', filename, line_counter, fline)
          break
        end
      end
    end
  end
  f:close()
  if err then return nil, err end
  return ini_table
end


function set (ini_table, filename)
  f = io.open(filename,'w')
  if not f then return nil, "cannot open file: " .. filename end
  f:write('; Created by inilazy (http://luaforge.net/projects/inilazy/)\n\n')
  for secname, sec in pairs(ini_table) do
    f:write("[", secname, "]\n")
    for keyname, key in pairs(sec) do
      for value, _ in pairs(key) do
        f:write(keyname, "=", value, "\n")
      end
    end
    f:write "\n"
  end
  f:close()
  return true
end

