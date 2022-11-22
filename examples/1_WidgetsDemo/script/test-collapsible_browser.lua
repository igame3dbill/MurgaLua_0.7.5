
-- b = browser name, included to make it easier
-- to plug this function into other scripts.
function toggle(b)
local count,state,one,two=1
-- selected line and its label
local me,label=b:value(),b:text(b:value())
if string.find(label,"%+%s*") then
  state,one,two="expanded","%+  ","%-  "
else
  state,one,two="collapsed","%-  ","%+  "
end
b:text(me,string.gsub(label,one,two)) -- swap + and -
-- optional output; cut off sep and the following + or - 
o:value("You "..state.." the "..string.gsub(label,sep..".%s*",""))
-- toggle all lines until reaching the next section or the browser end
while b:text(me+count) and not string.match(b:text(me+count),sep) do
  if state=="collapsed" then b:hide(me+count)
  else b:show(me+count)
  end
  count=count+1
end
end

ww=500; wh=200; f=10 -- window width, height, border
w=fltk:Fl_Window(ww,wh,"collapsible browser")
list=fltk:Fl_Hold_Browser(f,f,ww/2-f*2,wh-f*2)
list:selection_color(8)
h=fltk:Fl_Box(ww/2+f,f,ww/2-f*2,wh/2-f*2) -- help
h:align(149) -- align text inside top left
h:label([[Click the titles or press "Enter" to expand or collapse a section.

Press Alt+number to jump to the corresponding section.]])

function smove(me)
  local n=string.sub(me:label(),2) -- strip off "&"
  list:value(cat[tonumber(n)]) -- select the separator with index n
  local label=list:text(list:value()) -- get the text of selected line
  o:value("You jumped to the "..string.gsub(label,sep..".%s*",""))
  list:take_focus()
end
sbox=fltk:Fl_Box(ww/2+f,wh-f*8,f*3,f*2,"Move to section:")
sbox:align(20) -- inside left
-- buttons used to select section headers
s1=fltk:Fl_Button(ww-f*10,wh-f*8,f*3,f*2,"&1"); s1:callback(smove)
s2=fltk:Fl_Button(ww-f*7,wh-f*8,f*3,f*2,"&2"); s2:callback(smove)
s3=fltk:Fl_Button(ww-f*4,wh-f*8,f*3,f*2,"&3"); s3:callback(smove)
o=fltk:Fl_Output(ww/2+f,wh-f*4,ww/2-f*2,f*3) -- output

-- separator/subsection, prefix for the separator labels
-- format: bold text, gray background, underlined
sep="@b@B50@u"
t="    item:  " -- indentation

-- table to store the index of each separator
cat={}

-- contents of sections: label, item1, item2, ...
categories={
{sep.."-  first section","one-A","one-B","one-C"},
{sep.."-  second section","two A","to be","two C","two D"},
{sep.."-  third section","three-A","three-B","three-C","3-D","three-E","three-F"}
}

for k,v in ipairs(categories) do -- do each sub-table
  for i,s in ipairs(v) do
    if string.find(s,sep) then list:add(s); cat[k]=list:size() -- find the index of the separator
    else list:add(t..s) end -- add the string to the browser with optional indentation
  end
end
-- to start all collapsed, using the cat table to select the right lines
for k in ipairs(cat) do list:value(cat[k]); toggle(list) end
-- to start a specific section collapsed
--list:value(cat[3]); toggle(list)
list:value(1)
o:value("squishy browser demo")


list:callback( function()
if list:value()>0 then -- clicking a blank space can be fatal without this check
if Fl:event() == fltk.FL_RELEASE or Fl:event_key()==fltk.FL_Enter then -- on click or Enter
  if string.find(list:text(list:value()),sep) then toggle(list) -- if it's a separator
  else o:value([[You poked "]]..string.gsub(list:text(list:value()),t,"")..[["]]) -- print label to output, remove the indent
  end
end
end
end)
-- offscreen button that allows the list to respond to Enter key
enter=fltk:Fl_Return_Button(ww,wh,10,10)
enter:callback(function() list:do_callback() end)

w:show()
Fl:run()

