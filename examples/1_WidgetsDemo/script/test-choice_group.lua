
function flu_choice_group(x,y,w,h,tabs,table,label)
local g=fltk:Fl_Wizard(x,y,w,h,label)
g:align(11)
g:box(fltk.FL_EMBOSSED_FRAME)
fltk:Fl_End()
c=fltk:Fl_Choice(20,15,180,30)
c:callback(function() g:value(table[c:value()+1]) end)
if not tabs then local tabs=1 end
for i=1,tabs do
  table[i]=fltk:Fl_Group(x,y,w,h)
  fltk:Fl_End()
  g:add(table[i])
  c:add("tab "..i)
end
c:value(0)
end

page={} -- table for Fl_Wizard tabs
w=fltk:Fl_Window(400,300,"Choice_Group Test")

g=flu_choice_group(10,30,380,240,3,page,"Choice Group")

a1=fltk:Fl_Button(40,80,180,30,"button")
page[1]:add(a1)
b1=fltk:Fl_Button(40,80,180,30,"button")
b2=fltk:Fl_Button(40,115,180,30,"button")
page[2]:add(b1)
page[2]:add(b2)
c1=fltk:Fl_Button(40,80,180,30,"button")
c2=fltk:Fl_Button(40,115,180,30,"button")
c3=fltk:Fl_Button(40,150,180,30,"button")
page[3]:add(c1)
page[3]:add(c2)
page[3]:add(c3)

w:show()
Fl:run()
