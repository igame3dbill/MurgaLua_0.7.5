-- Demonstration of Fl_Positioner
-- Code by mikshaw (http://damnsmalllinux.org/cgi-bin/forums/ikonboard.cgi)

ww=350 --window width
wh=400 --window height
fw = ww-4
fh = ww-4
pw = fw-10
ph = fw-10

function thing_cb()
  xpos=string.format("%.2f",thing:xvalue()*pw)
  ypos=string.format("%.2f",thing:yvalue()*ph)
  square:position(xpos+2,ypos+2)
  out:value("X: ".. xpos .."  Y: ".. ypos)
  thing:hide()
  -- out:value("X: "..thing:xvalue() * ww .."  Y: "..thing:yvalue() * wh)
  w:redraw()
end

function square1_cb()
  square = square1
  -- thing:position(square1:x(),square1:y())
  thing:show()
  w:redraw()
end 

function square2_cb()
  square = square2
  -- thing:position(square1:x(),square1:y())
  thing:show()
  w:redraw()
end 

square = {}
w=fltk:Fl_Window(ww,wh,"murgaLua Positioner Demo")


frame=fltk:Fl_Box(2,2,fw,fh); 
frame:box(fltk.FL_BORDER_BOX)
frame:color(36);

square1 = fltk:Fl_Button(200,200,10,10); 
square1:box(fltk.FL_BORDER_BOX)
square1:color(60);
square1:callback(square1_cb)
square = square1

square2 = fltk:Fl_Button(50,50,10,10); 
square2:box(fltk.FL_BORDER_BOX)
square2:color(80);
square2:callback(square2_cb)

thing=fltk:Fl_Positioner(5,5,pw,ph,"percentage of window size"); 
thing:box(fltk.FL_NO_BOX)
thing:selection_color(36)
thing:callback(thing_cb)
thing:labeltype(fltk.FL_NO_LABEL);



out=fltk:Fl_Output(5,wh-30,ww/2,25)

w:show()
Fl:run()
