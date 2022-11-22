-- draws color cycling polygon squares at mouse
windowHeight, windowWidth = 480,480
counter = 0
quads={}
qx,qy=0,0
gridSize,quadSize=14,14 
qflip = false

function mouseDown_quads()
  flmousex=Fl:event_x()
  flmousey=Fl:event_y()
-- FL_DRAG =flevent 5 FL_PUSH =flevent 1, 
if  Fl:event()==5 or Fl:event()==1 then
doQuad=true
quadX=(math.floor((flmousex+(quadSize/2))/gridSize)*gridSize)-1
quadY=(math.floor((flmousey+(quadSize/2))/gridSize)*gridSize)-1

--don't draw in the same place twice, doQuad=qflip for fun 
for i=0,table.getn(quads),1 do
if  (quadX..","..quadY) == quads[i]  then doQuad=qflip end
end
end

if doQuad==true then drawQuad(quadX,quadY,quadSize) end

end   ---mouseDown_quads*

function drawQuad(qx,qy,qs,deltax,deltay)
quadHalf=math.floor(qs/2)
l,t,r,b=qx-quadHalf,qy-quadHalf,qx+quadHalf,qy+quadHalf
color_cycle(1,255,5)
-- --draw diagonal vector dependant on mouse movements      
   if qflip==false then 
     fltk.fl_loop(l,t,r,t,r,b)
      color_cycle(1,255,5)
      fltk.fl_loop(l,b,l,t,r,b)
   else 
      fltk.fl_loop(l,t,l,b,r,t)
      color_cycle(1,255,5)
      fltk.fl_loop(l,b,r,b,r,t) 
   end
   qflip=not qflip
   quadCount=table.getn(quads)+1
   quads[quadCount]=(quadX..","..quadY)
   doQuad=false    
end ---drawQuad

function color_cycle(baseColor,counterLimit,counterStep)
      counter=counter+counterStep
     if counter > counterLimit then counter=counterStep end
      fltk.fl_color(baseColor+counter)   
end ---color_cycle
      
---callback
function quad_draw_window_callback(eventValue)  
      w:make_current() -- whats this?
      mouseDown_quads()   
end ---color_cycle

----FLTK WINDOW 
w=fltk:Fl_Window(0,0, windowWidth, windowHeight, "Quad draw demo")
w:callback(quad_draw_window_callback)
w:color(55)
w:labelsize(9)
w:show()

--LOOP
while (Fl:event_key() ~= fltk.FL_Escape)  do
    Fl:check()
     w:do_callback()
end