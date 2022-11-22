
module ("string", package.seeall)

testing="This is mik's package"

-- will jumble an alphanumeric string
function jumble(s)
math.randomseed(os.time())
-- I didn't bother to deal with magic characters
-- other than to just ignore them.
s=string.gsub(s,"[%^%$%(%)%%%.%*%+%-%?]","_")
local len,new_s,idx,char=string.len(s),""
while string.len(new_s) < len do
  idx=math.random(string.len(s))
  char=string.sub(s,idx,idx)
  new_s=new_s..char
  s=string.gsub(s,char,"",1)
end
return new_s
end

