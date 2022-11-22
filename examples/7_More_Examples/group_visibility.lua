ww=180 --window dims
wh=200
gw=ww-20 -- group dims
gh=wh-50

w=fltk:Fl_Window(ww,wh,"Group Demo")
w:color(55)

group = fltk:Fl_Group(10,10,gw,gh)
group:box(fltk.FL_BORDER_BOX)
group:color(79)

  frame1=fltk:Fl_Box(20,20,50,50); 
  frame1:box(fltk.FL_BORDER_BOX)
  frame1:color(82)

  frame2=fltk:Fl_Box(100,100,50,50); 
  frame2:box(fltk.FL_BORDER_BOX)
  frame2:color(92)

fltk:Fl_End()

but = fltk:Fl_Light_Button(10,wh-30,80,22,"visible"); 
but:value(1)
but:callback(function(self)
  if (self:value() == 1) then 
    group:show() 
  else 
    group:hide()
  end
end)

w:show()
Fl:run()