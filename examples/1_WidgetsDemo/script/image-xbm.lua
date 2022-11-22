w=fltk:Fl_Double_Window(260,400,"image-xbm.lua")

xbm_box=fltk:Fl_Box(30,20,200,180)
xbm_box:box(fltk.FL_THIN_UP_BOX)
xbm_label=fltk:Fl_Box(30,200,200,30,"fltk:Fl_XBM_Image(filename)")

xbm_change_color=fltk:Fl_Button(30,240,200,30,"change &image color")
xbm_change_color:callback(
function(xbm_color_cb)
local newcolor=fltk.fl_show_colormap(xbm_box:labelcolor())
xbm_box:labelcolor(newcolor)
xbm_box:redraw()
end
)

xbm_change_bg=fltk:Fl_Button(30,270,200,30,"change &background")
xbm_change_bg:callback(
function(xbm_bg_cb)
local newcolor=fltk.fl_show_colormap(xbm_box:color())
xbm_box:color(newcolor)
xbm_box:redraw()
end
)

xbm_image=fltk:Fl_XBM_Image(images.."xbm_image.xbm")
xbm_box:image(xbm_image)

-- same as above:
--xbm_box:image(fltk:Fl_XBM_Image(demo_images.."xbm_image.xbm"))

xbm_box:tooltip("my_image:count() = "..xbm_image:count())
w:show()
Fl:run()
