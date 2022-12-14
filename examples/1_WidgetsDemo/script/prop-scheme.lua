w=fltk:Fl_Double_Window(480,300,"scheme.lua")

pack1=fltk:Fl_Pack(10,10,120,200)
fltk:Fl_Button(0,0,0,25,"Button")
fltk:Fl_Toggle_Button(0,0,0,25,"Toggle_Button")
fltk:Fl_Light_Button(0,0,0,25,"Light_Button")
fltk:Fl_Round_Button(0,0,0,25,"Round_Button")
fltk:Fl_Check_Button(0,0,0,25,"Check_Button")
thin=fltk:Fl_Button(0,0,0,25,"Thin Button")
out=fltk:Fl_Output(0,0,0,25)
fltk:Fl_End()
pack1:spacing(5)
thin:box(fltk.FL_THIN_UP_BOX)
out:value("text field")

pack2=fltk:Fl_Pack(140,10,160,200)
fltk:Fl_Adjuster(0,0,0,25)
fltk:Fl_Counter(0,0,0,25)
roll=fltk:Fl_Roller(0,0,0,55)
fltk:Fl_Hor_Slider(0,0,0,25)
fltk:Fl_Hor_Nice_Slider(0,0,0,25)
fltk:Fl_Hor_Value_Slider(0,0,0,25)
fltk:Fl_End()
pack2:spacing(5)
roll:type(fltk.FL_HORIZONTAL)

fltk:Fl_Tabs(310,10,160,115)
fltk:Fl_Group(310,30,160,95,"one")
fltk:Fl_End()
fltk:Fl_Group(310,30,160,95,"two")
fltk:Fl_End()
fltk:Fl_Group(310,30,160,95,"three")
fltk:Fl_End()
fltk:Fl_End()

brsr=fltk:Fl_Browser(310,130,160,145)
n=0
while n<20 do brsr:add("@cscroll ->"); n=n+1 end

pack3=fltk:Fl_Pack(10,260,280,20)
p=fltk:Fl_Radio_Round_Button(0,0,75,0,"Plastic")
g=fltk:Fl_Radio_Round_Button(0,0,75,0,"Gtk+")
n=fltk:Fl_Radio_Round_Button(0,0,75,0,"None")
fltk:Fl_End()
pack3:type(fltk.FL_HORIZONTAL)

p:callback(function() Fl:scheme("plastic") end)
g:callback(function() Fl:scheme("gtk+") end)
n:callback(function() Fl:scheme("none") end)

Fl:scheme("plastic")
p:value(1)

w:show()
Fl:run()
