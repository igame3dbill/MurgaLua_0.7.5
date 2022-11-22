fltk.fl_register_images()

function load_callback(object)
	fileName = fltk.fl_file_chooser("Choose an RGB image", "Image Files (*.{jpg,png})", "../images/icons.png", nil)
	image1 = Fl_Shared_Image.get(fileName)
	myImages = image1:getTiles(24,24)

	for key,value in pairs(myImages) do
		button1 = fltk:Fl_Button(59+(key*66), 10, 60, 60, "Tile " .. key)
		button1:image(value)
		group:add(button1)
		group:redraw()
	end
end

window = fltk:Fl_Window(325, 100, "Tile Demo")

button1=fltk:Fl_Button(5, 5, 110, 90, "Load image\n\nto be tiled")
button1:callback(load_callback)

group = fltk:Fl_Scroll(120, 5, 200, 90, "")
box = fltk:Fl_Box(120, 10,5,5, "")
group:add(box)
group:box(fltk.FL_THIN_UP_BOX)

-- group:add(button3)

window:resizable(group)

window:show()
Fl:run()
  