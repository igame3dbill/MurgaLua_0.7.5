w=fltk:Fl_Double_Window(510,340,"draw-curve.lua")

function draw_curve()
  w:make_current() -- needed for all drawing functions
  fltk.fl_color(fltk.FL_BLACK)
  fltk.fl_line_style(fltk.FL_SOLID)
  fltk.fl_font(fltk.FL_HELVETICA_BOLD,20)
  if curve_overlay:value() == 0 then
    -- draw a white box over the display area
    fltk.fl_color(fltk.FL_WHITE)
    fltk.fl_rectf(0,0,300,300)
    fltk.fl_color(fltk.FL_BLACK)
  end
  fltk.fl_begin_points() -- needed for curve/vertex drawing
  --fltk.fl_curve(0,vert_slides[0]:value(),100,vert_slides[1]:value(),200,vert_slides[2]:value(),300,vert_slides[3]:value())
  fltk.fl_curve(0,vert_slides[0]:value(),50,vert_slides[1]:value(),100,vert_slides[2]:value(),150,vert_slides[3]:value())
  fltk.fl_curve(150,vert_slides[3]:value(),200,vert_slides[4]:value(),250,vert_slides[5]:value(),300,vert_slides[6]:value())
  fltk.fl_end_points()
end

-- a white box over which to draw
curve_display=fltk:Fl_Box(0,0,300,300)
curve_display:color(fltk.FL_WHITE)
curve_display:box(fltk.FL_FLAT_BOX)

-- sliders control the vertical positions of the 4 points
vert_slides={}
for i=0,6 do
vert_slides[i]=fltk:Fl_Value_Slider(300+i*30,0,30,300)
vert_slides[i]:type(fltk.FL_VERTICAL)
vert_slides[i]:minimum(0)
vert_slides[i]:maximum(300)
vert_slides[i]:step(1)
vert_slides[i]:callback(draw_curve)
end

-- if this is enabled, the previous curve will not be erased (covered, actually)
curve_overlay=fltk:Fl_Round_Button(0,300,100,30,"overlay")
curve_overlay:type(fltk.FL_TOGGLE_BUTTON)
w:show()
Fl:run()
