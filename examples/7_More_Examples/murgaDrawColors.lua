windowHeight,windowWidth = 480,480
counter=0
rectLeft,rectTop,rectWidth,rectHeight = 4,11,10,10

function rectf_colorsgrid(eventValue)
      colornumber=1+counter
      fltk.fl_color(colornumber)
      w:make_current() -- whats this?
   fltk.fl_rectf(rectLeft,rectTop,rectWidth,12) 
     rectTop=rectTop+(rectHeight+2)
    rectTop,windowHeight,rectLeft,windowWidth=checkDrawBoundry(rectTop,windowHeight,rectLeft,windowWidth)
     counter=counter+1
     if counter > 255 then counter=1 end
end

function checkDrawBoundry(rectTop,windowHeight,rectLeft,windowWidth)
if rectTop > windowHeight-40 then
   rectTop=11
   rectLeft=rectLeft+(rectWidth)  
   if rectLeft+(rectWidth*4) > windowWidth then rectLeft,rectTop=4,11 end  ;
end
return rectTop,windowHeight,rectLeft,windowWidth
end


w=fltk:Fl_Window(0,0, windowWidth, windowHeight, "draw demo")
w:callback(rectf_colorsgrid)
w:color(55)
w:labelsize(9)
w:show()

while (Fl:event_key() ~= fltk.FL_Escape)  do
    Fl:check()
     w:do_callback()
end

