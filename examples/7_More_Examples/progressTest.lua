-- Demonstration of Fl_Progress
-- Code by mikshaw (http://damnsmalllinux.org/cgi-bin/forums/ikonboard.cgi)

ww=350 --window width
wh=100 --window height

w=fltk:Fl_Window(ww,wh,"murgaLua Progress Demo")

thing=fltk:Fl_Progress(10,10,ww-20,30,"0 %"); thing:box(fltk.FL_DOWN_BOX)
thing:selection_color(fltk.FL_BLACK)

function go_cb()
if thing:value() == 100 then
thing:selection_color(fltk.FL_BLACK)
thing:value(0)
else
if thing:value() >= 75 then thing:selection_color(fltk.FL_RED) end
thing:value(thing:value()+1)
end
thing:label(thing:value().." %")
end

go=fltk:Fl_Repeat_Button(10,50,ww-20,30,"hold me down"); go:callback(go_cb)

w:show()
Fl:run()
