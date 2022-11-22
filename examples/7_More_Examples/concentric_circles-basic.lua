--- concentric circles at mouse coordinates demo
--- mouse delta distance modifies circle height and width
windowHeight = 280
windowWidth = 320
centerx,centery=windowHeight/2,windowWidth/2
oldpointx,oldpointy=centerx,centery
counter = 96
lineStep=.1 -- increase for geometry
radiusStep=-.4 -- changes concentric density

function circles(cWidth,cHeight)
pi=3.14159
for ring=30,2,radiusStep do
radius=ring
C=2*pi

for cPoint=0,C,lineStep do
x=radius*math.cos(cPoint)*(cWidth/30)
y=radius*math.sin(cPoint)*(cHeight/30)
pointx=math.floor(Fl:event_x()+x)
pointy=math.floor(Fl:event_y()+y)
fltk.fl_loop(pointx,pointy,oldpointx,oldpointy,pointx,pointy)
oldpointx,oldpointy=pointx,pointy
end 
end 
end 

function draw_callback(eventValue)
      fltk.fl_color(96+counter)
      w:make_current() -- whats this?
      flmousex=math.abs(oldpointx-Fl:event_x())
  flmousey=math.abs(oldpointy-Fl:event_y())
      circles(flmousex,flmousey)
         counter=counter+2
     if counter > 128 then counter=2 end
end

w=fltk:Fl_Window(0,0, windowWidth, windowHeight, "circles demo")
w:callback(draw_callback)
w:color(55)
w:labelsize(9)
w:show()

while (Fl:event_key() ~= fltk.FL_Escape)  do
    Fl:check()
     w:do_callback()
end