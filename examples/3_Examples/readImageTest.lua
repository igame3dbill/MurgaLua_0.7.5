function readImage()
	window:make_current()
	imageString = fltk.fl_read_image(100, 30, 60, 110);
	image2 = fltk:Fl_RGB_Image(imageString, 60, 110, 3)
	button2:image(image2)
	window:redraw()
	Fl:check()
	fileName = fltk.fl_file_chooser("Save as", "Image Files (*.{xpm,gif,bmp,gif,jpg,png,pnm,xbm})", "test.png", nil)
	image2:saveAsPng(fileName)
end


fltk.fl_register_images()
fileName = fltk.fl_file_chooser("Choose a picture (eg. from examples/images)", "Image Files (*.{xpm,gif,bmp,gif,jpg,png,pnm,xbm})", "./images", nil)
image1 = Fl_Shared_Image.get(fileName)

window = fltk:Fl_Window(315, 145, "read_image test");

button1 = fltk:Fl_Button(5, 5, 210, 135, "Original Picture");
button2 = fltk:Fl_Button(220, 5, 90, 135, "read_image");

button1:image(image1)

timer = murgaLua.createFltkTimer()
timer:callback(readImage)

window:show()
timer:doWait(1)

Fl:run()
