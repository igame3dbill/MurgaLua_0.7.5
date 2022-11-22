--- FLTK DRAWING FUNCTIONS DEMO
--- mousedown changes the tool
--- endless concentric circle draing in every tool
-- Window Callback
function drawSampler_callback(eventValue)
math.randomseed(os.time())
      w:make_current() -- whats this?   
     doTools_circles((windowWidth*3),(windowHeight*3))     
end


quads={}
windowHeight = 300
windowWidth = 450

qflip = false

centerx=math.floor((windowWidth/2))
centery=math.floor((windowHeight/2))

intdx,intdy=20,20
doublea1,doublea2=1,360
intx1,inty1=centerx,centery

qx,qy=0,0
gridSize,quadSize=24,24


-- increase for geometry ,  changes total number of rings
lineStep , radiusStep =0.1 , -.8 

flmousex=Fl:event_x()
flmousey=Fl:event_y()
  flmousedx=flmousex-Fl:event_x()
  flmousedy=flmousex-Fl:event_y()
  tool=1
 
counter,subcount = 2,2
colorMod=-.088
function color_cycle()
    counter=counter+colorMod
     if counter>180 then colorMod=-(.1) end
      if counter<90 then colorMod=(.1) end
   
      theColor=math.floor(counter)
        --if theColor>200 then theColor=256-theColor end
    fltk.fl_color(theColor)
 end
 tool_names={"point"  ,"rectf"  ,"rectfrgb"  ,"rect"  ,"line"  ,"line_rect"  ,"loop_tri"  ,"loop_quad "  ,"poly_tri"  ,"poly_quad "  ,"line_yx "  ,"line_xy"  ,"angle_yx"  ,"angle_xy"  ,"rect_yx"  ,"rect_xy"  ,"quad_yx"  ,"quad_xy"  ,"arc" ,"pie"  ,"points"  ,"lines"  ,"loops"  ,"linesx2"  ,"polygons"  ,"complexpoly"  ,"curve"  ,"arcs"  ,"circles" }
function drawTool(tool)
  local t=tool
if t==1 or t=="point" then fltk.fl_point(intx,inty) 
elseif t==2  or t=="rectf" then fltk.fl_rectf(intx,inty,math.abs(intx-intx1),math.abs(inty-inty1))  
elseif t==3  or t=="rectfrgb" then  fltk.fl_rectf(intx,inty,5,5,256-theColor,theColor,-256+theColor)  
elseif t==4  or t=="rect" then  fltk.fl_rect(intx,inty,5,5,theColor)  
elseif t==5  or t=="line" then fltk.fl_line(intx1,inty1,intx,inty)  
elseif t==6  or t=="line_rect" then fltk.fl_line(intx1,inty1,intx1+x,inty1+y ,intx,inty)  
elseif t==7  or t=="loop_tri" then fltk.fl_loop(intx1,inty1,intx,inty,intx1,inty1)  
elseif t==8  or t=="loop_quad " then fltk.fl_loop(intx1,inty1,intx,inty1,intx,inty,intx1,inty)  
elseif t==9  or t=="poly_tri" then fltk.fl_polygon(intx1,inty1,intx,inty,centerx,centery)  
elseif t==10  or t=="poly_quad " then fltk.fl_polygon(intx1,inty1,intx,inty1,intx,inty,intx1,inty)  
elseif t==11  or t=="line_yx " then  fltk.fl_yxline(intx ,inty,inty1)  
elseif t==12  or t=="line_xy" then  fltk.fl_xyline(intx,inty,intx1)  
elseif t==13  or t=="angle_yx" then  fltk.fl_yxline(intx,inty,inty1,intx2)  
elseif t==14  or t=="angle_xy" then  fltk.fl_xyline(intx,inty,inty1,intx2)  
elseif t==15  or t=="rect_yx" then   fltk.fl_yxline(intx,inty,inty1,intx2,inty3)  
elseif t==16  or t=="rect_xy" then   fltk.fl_xyline(intx,inty,intx1,inty2,intx3)  
elseif t==17  or t=="quad_yx" then fltk.fl_yxline(intx,inty,inty1,intx2,inty3)  
elseif t==18  or t=="quad_xy" then fltk.fl_xyline(intx,inty,intx1,inty2,intx3)
elseif t== 19  or t=="arc"then fltk.fl_arc(intx, inty, intw, inth, doublea1, doublea2)
elseif t== 20 or  t=="pie" then  fltk.fl_pie(intx, inty, intw, inth, doublea1, doublea2)
elseif t== 21 or  t=="points" then 
fltk.fl_begin_points() 
fltk.fl_vertex(floatx, floaty)
fltk.fl_end_points()
elseif t== 22 or  t=="lines" then 
fltk.fl_begin_line()
fltk.fl_vertex(floatx, floaty)
fltk.fl_end_line()
elseif t== 23 or  t=="loops" then 
fltk.fl_begin_loop()
fltk.fl_vertex(floatx, floaty)
fltk.fl_vertex(intx1, inty1)
fltk.fl_end_loop()
elseif t== 24 or  t=="linesx2" then 
fltk.fl_begin_line()
fltk.fl_vertex(floatx, floaty)
fltk.fl_vertex(intx1, inty1)
fltk.fl_end_line()
elseif t== 25 or  t=="polygons" then 
fltk.fl_begin_polygon()
fltk.fl_vertex(centerx, centery)
fltk.fl_vertex(intx, inty)
fltk.fl_vertex(intx1, inty1)
fltk.fl_end_polygon()
elseif t== 26 or  t=="complexpoly" then 
fltk.fl_begin_complex_polygon() 
fltk.fl_vertex(floatx, floaty)
fltk.fl_vertex(flmousex, flmousey)
fltk.fl_vertex(floatx1, floaty1)
fltk.fl_end_complex_polygon()
elseif t== 27 or  t=="curve" then 
fltk.fl_begin_line()
fltk.fl_curve(flmousex, inty1, floatx, floaty, floatx1, floaty1,intx, flmousey)
--fltk.fl_curve(floatx, floaty, floatx1, floaty1, floatx2, floaty2, floatx3, floaty3)
fltk.fl_end_line()
elseif t== 28 or  t=="arcs" then 
fltk.fl_begin_line()
fltk.fl_arc(floatx, floaty, floatr, floatstart, floatend)
fltk.fl_end_line()
elseif t== 29 or  t=="circles" then 
fltk.fl_begin_line()
fltk.fl_circle(floatx, floaty, floatr)
fltk.fl_circle(flmousex, flmousey, floatr)
fltk.fl_end_line() 
end
end
 
function doTools_circles(cWidth,cHeight)
pi=3.14159for ring=30,2,radiusStep doradius=ringC=2*pi
for cPoint=0,C,lineStep do
 x=radius*math.cos(cPoint)*(cWidth/220)y=radius*math.sin(cPoint)*(cHeight/220)
flmousex=Fl:event_x()
flmousey=Fl:event_y()
floatx=(flmousex+x)
floaty=(flmousey+y)
intx=math.floor(floatx)inty=math.floor(floaty)

intx2=intx1
intx3=math.abs(flmousex) -- width
inty2=inty1
inty3=math.abs(flmousey) --height
inth =math.floor(ring/2)
intw=math.floor(ring/2)
floatr=ring-counter
floatstart, floatend = 1, ((34-ring) *12.1)
 if  Fl:event()==5 or Fl:event()==1 then  tool=tool+(.0011) end
    if tool > 29 then tool =1 end
color_cycle()
 drawTool(math.floor(tool)) 


intx1,inty1=intx,inty
floatx1,floaty1=floatx,floaty
  end 

end 
colorMod=colorMod*-1
doQuad=false
return end 






---FLTK WINDOW 
w=fltk:Fl_Window(0,0, windowWidth, windowHeight, "fltk graphics demo")
w:callback(drawSampler_callback)
w:color(55)
w:labelsize(9)

w:show()


while (Fl:event_key() ~= fltk.FL_Escape)  do

    Fl:check()
     w:do_callback()
end

