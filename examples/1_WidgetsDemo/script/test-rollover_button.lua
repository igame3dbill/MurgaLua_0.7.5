
w=fltk:Fl_Window(200,100,"Rollover Test")
b=fltk:Fl_Button(10,10,180,30,"rollover")

bg=b:color()
fg=b:labelcolor()
-- this probably shouldn't be a continuous loop
function loop()
if Fl:event_inside(b)==1 then
-- swap colors
b:color(fg); b:labelcolor(bg)
else
b:color(bg); b:labelcolor(fg)
end
b:redraw()
timer:doWait(0.05)
end

timer=murgaLua.createFltkTimer()
timer:callback(loop)
timer:do_callback()

w:show()
Fl:run()
