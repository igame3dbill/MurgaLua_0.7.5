w=fltk:Fl_Double_Window(210,290,"image-xpm.lua")
xpm_box=fltk:Fl_Box(20,20,140,140)
xpm_box:box(fltk.FL_BORDER_BOX)

xpm_file=images.."fish.xpm"

xpm_data=fltk:Fl_XPM_Image(xpm_file)
xpm_box:image(xpm_data)
xpm_box:tooltip("my_image:count() = "..xpm_data:count())
 
desaturate=fltk:Fl_Button(20,160,140,30,"desaturate")
desaturate:callback(function(desat_cb)
xpm_data:desaturate()
xpm_box:redraw_label()
end
)
inactive=fltk:Fl_Button(20,190,140,30,"inactive")
inactive:callback(function(inact_cb)
xpm_data:inactive()
xpm_box:redraw_label()
end
)
reset=fltk:Fl_Button(20,220,140,30,"reset")
reset:callback(function(reset_cb)
xpm_data:uncache()
xpm_data=fltk:Fl_XPM_Image(xpm_file)
xpm_box:image(xpm_data)
xpm_box:redraw_label()
end
)

color_button=fltk:Fl_Button(160,220,30,30,"color_average @8->")
color_button:align(10)
color_button:color(fltk.FL_RED)
color_button:callback(function(cb_cb)
local newcolor=fltk.fl_show_colormap(color_button:color())
color_button:color(newcolor)
color_slider:do_callback()
end
)
color_slider=fltk:Fl_Value_Slider(160,20,30,200)
color_slider:minimum(0)
color_slider:maximum(1)
color_slider:step(0.1)
color_slider:value(1)
color_slider:callback(function(cscb)
reset:do_callback()
xpm_data:color_average(color_button:color(),color_slider:value())
xpm_box:redraw_label()
end
)
w:show()
Fl:run()
