local Public = {}
concatxmlgen = Public

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

local function return_xml_attributes(attr)
  local s = ""
  for i,v in attr do
    s = s.." "..i.."='"..xml_quote_attr(v).."'"
  end
  return s
end

local return_xml
function return_xml(t)
  if type(t) == "string" then
    return xml_quote(t)
  elseif type(t) == "table" then
    local s = "<"..t.name
    if t.attr then s=s..return_xml_attributes(t.attr) end
    s = s..">"
    for i,v in ipairs(t) do
      s = s..return_xml(v)
    end
    s = s.."</"..t.name..">"
    return s
  else
    error("unknown xml content")
  end
end

Public.return_xml = return_xml

return Public
