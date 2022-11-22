window=fltk:Fl_Window(100,100,800,600,"Test Window")
background=fltk:Fl_Box(0,0,800,600)
image_master_back=fltk:Fl_PNG_Image("murgaLua_badge.png")
--image_master_back=fltk:Fl_JPG_Image("someJPEG.jpg")
background:image(image_master_back)
window:show()
Fl:run();
