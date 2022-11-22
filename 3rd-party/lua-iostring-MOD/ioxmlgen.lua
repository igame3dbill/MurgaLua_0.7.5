--[[ 
doc = {name="myroot", "text&more><", {name="empty", attr={remark="don't"}}}

st = iostring.newoutput()
write_xml(st, doc)
print(st:getstring())
]]

local Public = {}
ioxmlgen = Public

-- Convert an XML table to a string:

-- note that these two functions are responsible for about a quarter of
-- CPU time for file and ciostring runs...

local function xml_quote(s)
  s = string.gsub(s, "&", "&amp;")
  s = string.gsub(s, "<", "&lt;")
  s = string.gsub(s, ">", "&gt;")
  return s
end

local function xml_quote_attr(s)
  s = xml_quote(s)
  s = string.gsub(s, "'", "&apos;")
  return s
end

local function write_xml_attributes(file, attr)
  for i,v in attr do
    file:write(" "..i.."='"..xml_quote_attr(v).."'")
  end
end

local write_xml
function write_xml(file, t)
  if type(t) == "string" then
    file:write(xml_quote(t))
  elseif type(t) == "table" then
    file:write("<"..t.name)
    if t.attr then write_xml_attributes(file, t.attr) end
    file:write(">")
    for i,v in ipairs(t) do
      write_xml(file, v)
    end
    file:write("</"..t.name..">")
  else
    error("unknown xml content")
  end
end


Public.write_xml = write_xml

return Public
