window = fltk:Fl_Window(505, 145, "My first little app");

firstButton = fltk:Fl_Button(5, 5, 310, 135, "My First Button");
loadImage = fltk:Fl_Button(320, 65, 180, 35, "Load a picture");
quitButton = fltk:Fl_Button(320, 105, 180, 35, "Quittin Time");

slider = fltk:Fl_Slider(320, 10, 180, 30, "Size Me");
slider:type(1)
slider:range(5, 55)
slider:step(1)
slider:value(firstButton:labelsize())

slider:callback(
	function(slider)
		   firstButton:labelsize(slider:value())
		   firstButton:label("My size is " .. slider:value())
		   firstButton:redraw()
	end)

function quit_callback(object)
   if fltk.fl_ask("Are you sure ?") >= 1 then
      window:hide()
   end
end

window:callback(quit_callback)
quitButton:callback(quit_callback)

function loadImage_callback(object)
	fltk.fl_register_images()
	fileName = fltk.fl_file_chooser("Choose a picture", "Image Files (*.{bmp,gif,jpg,png})", nil, nil)
	image = Fl_Shared_Image.get(fileName)
	firstButton:image(image)
	firstButton:redraw()
end

loadImage:callback(loadImage_callback)
	
window:show()
Fl:run()
