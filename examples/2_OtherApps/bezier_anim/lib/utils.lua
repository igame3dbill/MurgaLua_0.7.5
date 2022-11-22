--[[
**********************************************************
*    Utils
*
*   The <utils.lua> script provides functions that are 
*   often reused across projects
*  
*   @author:     Marielle Lange 
*   @date:       2007-05-27
*   @version:    0.1 
*   @support:    Lua 5.1, murgaLua ???
***********************************************************/
]]


--[[
--  round
--  
--  Round the given number to the given number of decimal (or 0 
--  decimals if no decimals are provided
]]

function round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

--[[
--  serialize
--  
--  produces a printable form for objects. Useful when using 
--  io.write to log object content into an output file
--  
--  @credits  copied from Programming in Lua, by Roberto Ierusalimschy 
--            12.1.1 - Saving Tables without Cycles. url: http://www.lua.org/pil/12.1.1.html 
]]
function serialize(o)
  if type(o) == "number" then
    io.write(o)
  elseif type(o) == "string" then
    io.write(string.format("%q", o))
  elseif type(o) == "table" then
    io.write("{\n")
    for k,v in pairs(o) do
      io.write("  ", k, "=")
      serialize(v)
      io.write(",\n")
    end
    io.write("}\n")
  else
    error("cannot serialize a " .. type(o))
  end
end