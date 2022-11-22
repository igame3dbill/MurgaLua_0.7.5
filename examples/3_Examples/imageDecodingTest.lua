fltk.fl_register_images()
fileName = fltk.fl_file_chooser("Choose a picture (eg. from images dir)", "Image Files (*.{xpm,gif,bmp,gif,jpg,png,pnm,xbm})", "./images", nil)
image1 = Fl_Shared_Image.get(fileName)

imageExt = image1:name():sub(-3)
print ("Image is of extension : " .. imageExt .. " Array count is : " .. image1:count())
io.flush()

test = image1:data()

if (image1:count() > 2) then -- It's a Pixmap
	image2 = fltk:Fl_Pixmap(test)
end
if (image1:count() == 1 and image1:d() > 1) then -- It's a RGB image
	image2 = fltk:Fl_RGB_Image(test[1], test["w"], test["h"], test["d"], test["ld"])
end
if (image1:count() == 1 and image1:d() == 0) then -- It's a Bitmap
	image2 = fltk:Fl_Bitmap(test[1], test["w"], test["h"])
end

-- This is not always a good idea as array my contain binary data
-- that will kill the terminal ...
-- murgaLua.debug.printTable(test)
-- io.flush()

window = fltk:Fl_Window(435, 145, "Image loading test");

button1 = fltk:Fl_Button(5, 5, 210, 135, "Original Picture");
button2 = fltk:Fl_Button(220, 5, 210, 135, "Image loaded from table");

button1:image(image1)
button2:image(image2)

window:show()
Fl:run()
