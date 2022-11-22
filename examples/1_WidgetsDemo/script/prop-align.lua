w=fltk:Fl_Double_Window(500,400,"align.lua")

albox=fltk:Fl_Box(120,100,200,120,
[[When you set an image to a widget,
it becomes a part of the widget's label and will be affected by align()

lalalalalalalalalalalalalalalalalalalalalalalalalongstringofnonbreakingtextlalalalalalala
]])
albox:box(fltk.FL_BORDER_BOX)
albox:image(fltk:Fl_XPM_Image(images.."eyes.xpm"))

ukslide = fltk:Fl_Value_Slider(20,300,400,30)
ukslide:type(fltk.FL_HORIZONTAL)
ukslide:align(fltk.FL_ALIGN_TOP)
ukslide:step(1)
ukslide:minimum(0)
ukslide:maximum(255)
ukslide:callback(
function(ukslide_cb)
  albox:hide()
  albox:align(ukslide:value())
  albox:show()
end
)

Fl:focus(ukslide)
w:show()
Fl:run()
