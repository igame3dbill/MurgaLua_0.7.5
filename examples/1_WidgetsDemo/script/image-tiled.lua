w=fltk:Fl_Double_Window(470,400,"image-tiled.lua")

my_tile_image=fltk:Fl_JPEG_Image(images.."tile.jpg")
my_tile=fltk:Fl_Tiled_Image(my_tile_image,450,300)
my_tile_w=my_tile_image:w()
my_tile_h=my_tile_image:h()

-- same as above (without the width/height feature):
--my_tile=fltk:Fl_Tiled_Image(fltk:Fl_JPEG_Image(demo_images.."tile.jpg"),450,300)

tile_box_label=fltk:Fl_Box(10,10,450,60,"fltk:Fl_Tiled_Image(imagename,w,h)\noriginal image size: "..my_tile_w.."x"..my_tile_h)
tile_box=fltk:Fl_Box(10,70,450,300)
tile_box:image(my_tile)

w:show()
Fl:run()
