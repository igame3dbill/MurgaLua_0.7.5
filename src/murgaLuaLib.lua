--[[

  murgaLua
  Copyright (C) 2006-12 John Murga
  
  This program is free software; you can redistribute it and/or
  modify it under the terms of the GNU General Public License
  as published by the Free Software Foundation; either version 2
  of the License, or (at your option) any later version.
  
  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.
  
  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the :
  
    Free Software Foundation, Inc.
    51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
  
]]

local base = _G

module("murgaLua")

--
-- This is where interesting functions impleted in the lua language itself go.
--
-- The first two in the series are inspired by code I had seen at :
--  http://www.gammon.com.au/welcome.html
--


-- Nice table filter / copy function :-)

-- Basically provide a function that returns true when you want an item to
-- copied ... That way you can filter your table..

function filterTable (myTable, myFunction)

  -- Check your parameters
  base.assert (base.type (myTable) == "table")
  base.assert (base.type (myFunction) == "function")

  -- Work variables
  local myKey, myValue
  local resultTable = {}

  -- And then just a simple loop to perfom the filter/insert
  base.table.foreach(myTable, function (myKey, myValue)
    if myFunction (myValue) then
    resultTable[myKey] = myValue
 --     base.table.insert (resultTable, myValue)
 --     resultTable.__public[# resultTable] = myKey
    end
  end
  )
  
  -- Return the new table
  return resultTable
  
end

function findXmlNode (xmlTable, elementPath)
  currentNode = xmlTable
  
  for currentElement in base.string.gmatch(elementPath, "([^/]+)") do
    currentNode = findNextXmlNode(currentNode, currentElement)
    if not currentNode then break end
  end
  
  return currentNode
end

function findNextXmlNode (xmlTable, nodeName, instance)
  if not xmlTable.n then return nil end
  if not instance then instance = 1 end
  
  currentInstance = 1
  
  for counter=1,xmlTable.n do
    if (xmlTable[counter].name == nodeName) then
      if (currentInstance == instance) then
        return xmlTable[counter]
      end
      currentInstance = currentInstance + 1
    end 
  end
  
  return nil
end

function exportXml(xmlNode, outFile, indent)
  if not indent then indent=-4 end -- Big HACK
    
  if base.type(xmlNode) == "table" then
      exportXmlTable(xmlNode, outFile, indent)
  else
      exportXmlString(xmlNode, outFile, indent)
  end
end

function exportXmlTable(xmlNode, outFile, indent)

  endChars = ">\n"
  if (xmlNode.n == nil) then endChars = "/>\n" end
  
  if (xmlNode.name ~= nil) then
    outFile:write(base.string.rep (" ", indent) .. "<" .. xmlNode.name .. exportXmlAttrs(xmlNode.attr) .. endChars)
  end
  
  if (xmlNode.n ~= nil) then
    for counter=1,xmlNode.n do
      exportXml(xmlNode[counter], outFile, indent+4)
    end
  end
  
  if (xmlNode.name ~= nil and xmlNode.n ~= nil) then
    outFile:write(base.string.rep (" ", indent) .. "</" .. xmlNode.name .. ">\n")
  end
end

function exportXmlString(xmlNode, outFile, indent)
  if (base.string.find(xmlNode, "  ") or base.string.find(xmlNode, "\n")
      or base.string.find(xmlNode, "<") or base.string.find(xmlNode, "&")) then
    outFile:write(base.string.rep (" ", indent) .. "<![CDATA[" .. xmlNode .. "]]>\n")
  else
    outFile:write(base.string.rep (" ", indent) .. xmlNode .. "\n")
  end
end

function exportXmlAttrs(myTable, outFile)
  attrStr = ""
  if (myTable) then
    for key, value in base.pairs (myTable) do
      if (base.string.find(value, "\"") or base.string.find(value, "&")) then
        value = base.string.gsub(value, "&", "&amp;")
        value = base.string.gsub(value, "\"", "&quot;")
      end
      attrStr = attrStr .. " " .. key .. "=\"" .. value .. "\""
    end
  end
  
  return attrStr
end

-- This call is a clone of sleep that I created in the socket library
function sleep (milliseconds)
    base.murgaLua.sleepMilliseconds(milliseconds)
end

-- This creates a dummy time control
function createFltkTimer()
    return base.fltk:Fl_murgaLuaTimer(0,0,0,0,"")
end

-- This creates an offscreen buffer
function createOffscreenBuffer(width, height)
    return base.fltk:Fl_murgaLuaOffScreen(width, height)
end

function compileMurgaLua (in_filename, in_executable, out_filename)

  base.print ("MurgaLua compiler 1.0")
  base.print ("=====================")
  
  inf  = base.io.open(in_executable,  "rb")
  outf = base.io.open(out_filename, "wb")
  
  outf:write(inf:read("*a"))
  
  endOfFile = outf:seek("end")
  
  outf:close()
  inf:close()
  
  base.print ("Loading core murgaLua executable ...")
  
  inf  = base.io.open(in_filename,  "rb")
  outf = base.io.open(out_filename, "ab")
  
  base.print ("Binding compressed code ...")
  -- Read, compress & write
  outf:write(base.lzo.compress(inf:read("*a")))

  base.print ("Writing executable stub info ...")
  -- Write executable information
  outf:write("_murgaLuaBinary_" .. base.string.format("%8i", endOfFile))
  
  outf:close()
  inf:close()

  base.print ("Done !!")
  
end

function decompileMurgaLua (in_filename, out_filename)

  if out_filename then
    base.print ("MurgaLua deCompiler 1.0")
    base.print ("=======================")
  end

	inf  = base.io.open(in_filename,  "rb")
	
	-- base.print("Filename " .. in_filename)
	-- Under Windows the executable may be invoked without a ".exe"
	if (inf == nil) then
		inf  = base.io.open(in_filename .. ".exe",  "rb")
		if (inf == nil) then
		  return
		end
	end
	
	endOfFile = inf:seek("end")

	endOfFile = endOfFile - 24
	inf:seek("set", endOfFile)
	marker = inf:read("*line")

  if out_filename then
  	base.print("Looking for executable stub info at : " .. endOfFile)
  end

  if not marker then
    marker = ""
  end

	startOfLz = 0
	if (base.string.find(marker, "_murgaLuaBinary_")) then
	   startOfLz = base.string.sub(marker, 17)
	else
     if out_filename then
	     base.print ("No executable stub info found !!")
	   end
	   return
	end
	
	inf:seek("set", startOfLz)
	
	-- Read, de-compress & write
	programCode = base.lzo.decompress(inf:read("*a"));
	inf:close()
	
	if out_filename then
    base.print ("Writing original murgaLua source code ...")
  	outf = base.io.open(out_filename, "wb")
  	outf:write(programCode)
  	outf:close()
    base.print ("Done !!")
  else
    newFunc = base.loadstring(programCode)
    newFunc()
    base.os.exit()
  end
end

-- More functions

function roundNumber(num, idp)
  local mult = 10^(idp or 0)
  return base.math.floor(num * mult + 0.5) / mult
end

-- Convert from CSV string to table
function getTableFromCSV (s)
  s = s .. ','        -- ending comma
  local t = {}        -- table to collect fields
  local fieldstart = 1
  repeat
    -- next field is quoted? (start with `"'?)
    if string.find(s, '^"', fieldstart) then
      local a, c
      local i  = fieldstart
      repeat
        -- find closing quote
        a, i, c = string.find(s, '"("?)', i+1)
      until c ~= '"'    -- quote not followed by quote?
      if not i then error('unmatched "') end
      local f = string.sub(s, fieldstart+1, i-1)
      table.insert(t, (string.gsub(f, '""', '"')))
      fieldstart = string.find(s, ',', i) + 1
    else                -- unquoted; find next comma
      local nexti = string.find(s, ',', fieldstart)
      table.insert(t, string.sub(s, fieldstart, nexti-1))
      fieldstart = nexti + 1
    end
  until fieldstart > string.len(s)
  return t
end

-- Nasty table count as we are using hash tables
function getTableSize(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

-- Find an item in a numbered table
function findInTable(T, O)
  for K, I in pairs(T) do
    if O == I then
      return K
    end
  end
  return 0
end

-- Lua TRIM
function trimString(s)
  return s:match'^()%s*$' and '' or s:match'^%s*(.*%S)'
end

-- Taken from FL/Enumerations.H
function getFltkEventText(currentEvent)
	if base.tonumber(currentEvent) then
		local events = {
		  "FL_NO_EVENT",
		  "FL_PUSH",
		  "FL_RELEASE",
		  "FL_ENTER",
		  "FL_LEAVE",
		  "FL_DRAG",
		  "FL_FOCUS",
		  "FL_UNFOCUS",
		  "FL_KEYDOWN",
		  "FL_KEYUP",
		  "FL_CLOSE",
		  "FL_MOVE",
		  "FL_SHORTCUT",
		  "FL_DEACTIVATE",
		  "FL_ACTIVATE",
		  "FL_HIDE",
		  "FL_SHOW",
		  "FL_PASTE",
		  "FL_SELECTIONCLEAR",
		  "FL_MOUSEWHEEL",
		  "FL_DND_ENTER",
		  "FL_DND_DRAG",
		  "FL_DND_LEAVE",
		  "FL_DND_RELEASE" }
		return(events[currentEvent+1])
	end
	return ""
end

-- Host OS name command should be concatenated here.
