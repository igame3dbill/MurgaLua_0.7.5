--- concentric circles at mouse coordinates demo
--- mouse delta distance modifies circle height and width
windowHeight = 280
windowWidth = 320
centerx,centery=windowHeight/2,windowWidth/2
oldpointx,oldpointy=centerx,centery
counter,subcount = 2,2
lineStep=.1 -- increase for geometry
radiusStep=-.4--  changes total number of rings
loopDirection=-.088
function color_cycle()
 counter=counter+loopDirection
if counter>128 then loopDirection=-.124 end
if counter<2 then loopDirection=.124 end
fltk.fl_color(Fl:event_y()+math.floor(counter))
 end
 
function twirl_circles(cWidth,cHeight)pi=3.14159for ring=30,2,radiusStep doradius=ringC=2*pi

for cPoint=0,C,lineStep dox=radius*math.cos(cPoint)*(cWidth/20)y=radius*math.sin(cPoint)*(cHeight/20)pointx=math.floor(centerx+x)pointy=math.floor(centery+y)

fltk.fl_loop(centerx,centerx,oldpointx,oldpointy,pointx,pointy)
oldpointx,oldpointy=pointx,pointy
color_cycle()end 
end 
return end 

function twirl_callback(eventValue)
      w:make_current() -- whats this?
      flmousex=oldpointx-Fl:event_x()
  flmousey=oldpointy-Fl:event_y()
  --radiusStep=-math.abs(flmousex)*.01
      twirl_circles(150+(flmousex/10),150+(flmousey/10))
end

w=fltk:Fl_Window(0,0, windowWidth, windowHeight, "circles demo")
w:callback(twirl_callback)
w:color(55)
w:labelsize(9)
w:show()

while (Fl:event_key() ~= fltk.FL_Escape)  do
    Fl:check()
     w:do_callback()
end

