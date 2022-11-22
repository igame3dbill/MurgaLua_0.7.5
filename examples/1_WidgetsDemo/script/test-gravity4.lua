w=fltk:Fl_Double_Window(600,400,"gravity4.lua")

balls=500
bsize=2
min_grav=0
max_grav=10
w:color(0)

function grav_loop()
local my_x,bx,xspeed=Fl:event_x(),0,0
local my_y,by,yspeed=Fl:event_y(),0,0
local c=math.random(1,255) -- a random color
  for i=1,balls do
    local xdistance=math.abs(my_x-ball[i]:x())
    local ydistance=math.abs(my_y-ball[i]:y())
    local distance=math.sqrt(xdistance*xdistance+ydistance*ydistance)
    if distance <= 25 then -- warp it
      ball[i]:color(c)
      c=math.random(1,4)
      if c==1 then bx=ball[i]:x()+max_x; by=math.random(1,max_y) -- right
      elseif c==2 then bx=math.random(1,max_x); by=ball[i]:y()+max_y -- bottom
      elseif c==3 then by=math.random(1,max_y); bx=ball[i]:x()-max_x -- left
      elseif c==4 then by=ball[i]:y()-max_y; bx=math.random(1,max_x) -- top
      end
      ball[i]:position(bx,by)
    else 
      xspeed=(min_grav+max_grav)/distance*xdistance
      yspeed=(min_grav+max_grav)/distance*ydistance
      if my_x > ball[i]:x() then bx=ball[i]:x()+xspeed else bx=ball[i]:x()-xspeed end
      if my_y > ball[i]:y() then by=ball[i]:y()+yspeed else by=ball[i]:y()-yspeed end
      ball[i]:position(bx,by)
    end
  end
w:redraw()
grav_timer:doWait(.05)
end


math.randomseed(os.time())
max_x=w:w()-bsize
max_y=w:h()-bsize
ball={}
for i=1,balls do
ball[i]=fltk:Fl_Box(math.random(1,max_x),math.random(1,max_y),bsize,bsize)
ball[i]:box(fltk.FL_FLAT_BOX)
end

grav_timer = murgaLua.createFltkTimer()
grav_timer:callback(grav_loop)
grav_timer:do_callback()

w:show()
Fl:run()
