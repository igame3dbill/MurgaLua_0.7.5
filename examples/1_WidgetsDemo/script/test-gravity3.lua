w=fltk:Fl_Double_Window(600,400,"gravity3.lua")

w:color(0)
balls=250
bsize=10

function grav_loop()
local my_x,bx=Fl:event_x(),0
local my_y,by=Fl:event_y(),0
local c=math.random(1,255)
local b=math.random(1,balls)
ball[b]:color(c)
  for i=1,balls do
    local xdistance=math.abs(my_x-ball[i]:x())
    local ydistance=math.abs(my_y-ball[i]:y())
    local distance=math.sqrt(xdistance*xdistance+ydistance*ydistance)
    local speed=max_slider:value()/distance
    if distance > 0 then
      if my_x > ball[i]:x() then
        bx=ball[i]:x()+speed
      else
        bx=ball[i]:x()-speed
      end
      if my_y > ball[i]:y() then
        by=ball[i]:y()+speed
      else
        by=ball[i]:y()-speed
      end
      ball[i]:position(bx,by)
    end
  end
w:redraw()
grav_timer:doWait(.05)
end

fltk.fl_define_FL_RFLAT_BOX()
math.randomseed(os.time())
max_x=w:w()-bsize
max_y=w:h()-bsize
ball={}
for i=1,balls do
ball[i]=fltk:Fl_Box(math.random(1,max_x),math.random(1,max_y),bsize,bsize)
if fltk._FL_RFLAT_BOX then ball[i]:box(fltk._FL_RFLAT_BOX) else ball[i]:box(fltk.FL_RFLAT_BOX) end
end

max_slider=fltk:Fl_Hor_Value_Slider(0,w:h()-20,w:w(),20)
max_slider:minimum(50)
max_slider:maximum(5000)
max_slider:value(500)
max_slider:step(1)

grav_timer = murgaLua.createFltkTimer()
grav_timer:callback(grav_loop)
grav_timer:do_callback()
w:show()
Fl:run()
