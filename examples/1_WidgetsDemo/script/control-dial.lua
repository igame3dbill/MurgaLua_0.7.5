w=fltk:Fl_Double_Window(420,180,"dial.lua")
-- dial widget

dial_out = fltk:Fl_Value_Output(50,20,60,20)
link = fltk:Fl_Round_Button(310,20,60,20,"link")
link:type(fltk.FL_TOGGLE_BUTTON)

function dial_update(self)
dial_out:value(self:value()) -- set output display to dial value
end

normal = fltk:Fl_Dial(50,60,60,60,"FL_NORMAL_DIAL")
normal:step(1)
normal:minimum(-100)
normal:maximum(100)
normal:value(10) -- default is 0
normal:callback(dial_update)

line = fltk:Fl_Dial(180,60,60,60,"FL_LINE_DIAL")
line:step(1)
line:minimum(-100)
line:maximum(100)
line:type(fltk.FL_LINE_DIAL)
line:color(10)
line:selection_color(1)
line:callback(dial_update)

fill = fltk:Fl_Dial(310,60,60,60,"FL_FILL_DIAL")
fill:step(10)
fill:minimum(0)
fill:maximum(100)
fill:type(fltk.FL_FILL_DIAL)
fill:color(7) -- background
fill:selection_color(15) -- fill
fill:angles(90,270)
fill:callback(function(fill_cb)
dial_out:value(fill:value())
if link:value() == 1 then normal:value(fill:value()); line:value(fill:value()) end
end
)

dial_out:value(normal:value())
w:show()
Fl:run()
