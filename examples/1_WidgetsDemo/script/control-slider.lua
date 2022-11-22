-- slider widget

w=fltk:Fl_Double_Window(500,300,"slider.lua")

slide_output = fltk:Fl_Value_Output(50,10,60,20)
slide_link = fltk:Fl_Round_Button(120,10,60,20,"link")
slide_link:type(fltk.FL_TOGGLE_BUTTON)

slide = fltk:Fl_Hor_Slider(50,30,200,30,"Fl_Slider") -- same as the next 2 lines
--slide = fltk:Fl_Slider(50,30,200,30,"Fl_Slider")
--slide:type(fltk.FL_HORIZONTAL)
slide:align(fltk.FL_ALIGN_RIGHT)
slide:step(1)
slide:minimum(-100)
slide:maximum(100)
slide:callback(function(slide_cb)
slide_output:value(slide:value())
if slide_link:value() == 1 then slide_nice:value(slide:value()) end
end
)

--slide_nice = fltk:Fl_Hor_Value_Slider(50,70,200,30,"Fl_Value_Slider - pretty")
slide_nice = fltk:Fl_Value_Slider(50,70,200,30,"Fl_Value_Slider - pretty")
slide_nice:type(fltk.FL_HOR_NICE_SLIDER)
slide_nice:align(fltk.FL_ALIGN_RIGHT)
slide_nice:step(1)
slide_nice:minimum(-100)
slide_nice:maximum(100)
slide_nice:value(42)
slide_nice:callback(function(slide_nice_cb)
slide_output:value(slide_nice:value())
if slide_link:value() == 1 then slide:value(slide_nice:value()) end
end
)

vslide = fltk:Fl_Value_Slider(75,110,30,100,"Fl_Value_Slider - plain")
vslide:type(fltk.FL_VERTICAL)
vslide:align(fltk.FL_ALIGN_BOTTOM)
vslide:step(10)
vslide:minimum(100)
vslide:maximum(0)
vslide:callback(function(vslide_cb)
slide_output:value(vslide:value())
end
)

vslide_nice = fltk:Fl_Value_Slider(200,140,30,100,"Fl_Value_Slider - pretty")
vslide_nice:type(fltk.FL_VERT_NICE_SLIDER)
vslide_nice:color(14)
vslide_nice:selection_color(13)
vslide_nice:textcolor(7)
vslide_nice:align(fltk.FL_ALIGN_BOTTOM)
vslide_nice:step(1)
vslide_nice:minimum(100)
vslide_nice:maximum(0)
vslide_nice:callback(function(vslide_nice_cb)
slide_output:value(vslide_nice:value())
end
)
w:show()
Fl:run()
