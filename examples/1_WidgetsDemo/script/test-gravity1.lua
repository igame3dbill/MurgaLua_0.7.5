w=fltk:Fl_Double_Window(600,400,"gravity1.lua")


function grav_loop()
local my_x,bx=Fl:event_x(),0
local my_y,by=Fl:event_y(),0
  for i=1,100 do
    if my_x > balls[i]:x() then bx=balls[i]:x()+1 else bx=balls[i]:x()-1 end
    if my_y > balls[i]:y() then by=balls[i]:y()+1 else by=balls[i]:y()-1 end
    balls[i]:position(bx,by)
  end
  w:redraw()
  grav_timer:doWait(.05)
end

fltk.fl_define_FL_OVAL_BOX()
math.randomseed(os.time())
max_x=w:w()-10
max_y=w:h()-10
balls={}
for i=1,100 do
balls[i]=fltk:Fl_Box(math.random(1,max_x),math.random(1,max_y),10,10)
if fltk._FL_OVAL_BOX then balls[i]:box(fltk._FL_OVAL_BOX) else balls[i]:box(fltk.FL_OVAL_BOX) end
end

grav_timer = murgaLua.createFltkTimer()
grav_timer:callback(grav_loop)
grav_timer:do_callback()
w:show()
Fl:run()
