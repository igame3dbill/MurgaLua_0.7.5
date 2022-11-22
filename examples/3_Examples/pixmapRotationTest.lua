function pixMapRotate(image, theta)

    theta = theta/57.3

	imageData = image:data();
	newImageData = {}
	newHeaderInfo = {}
	newImageData[1] = imageData[1]

	counter = 1
	for aNumber in string.gmatch(imageData[1], "[%w-]+") do
		newHeaderInfo[counter] = tonumber(aNumber)
		counter = counter + 1
	end
	
	colourHeaders = newHeaderInfo[3]
	if (colourHeaders < 1) then
		colourHeaders=1
	end
	
	for counter=1,colourHeaders,1 do
		newImageData[counter+1] = imageData[counter+1]
	end

	width = image:w();
	height = image:h();
	
	-- print ("Image width = " .. width .. " Image height " .. height .. " Colour headers " .. colourHeaders)
	
	for destY=1,height,1 do
		for destX=1,width,1 do
			if (destX == 1) then
				newImageData[destY+colourHeaders+1] = ""
			end
			-- Move origin to the Center
			x0 = destX-width/2
			y0 = destY-width/2
			-- Rotate to the source image
			xr = x0 * math.cos(theta) + y0 * math.sin(theta)
			yr = x0 * -math.sin(theta) + y0 * math.cos(theta)
			-- Translate to the source image origin
			xs = murgaLua.roundNumber(xr + height/2)
			ys = murgaLua.roundNumber(yr + width/2)
			-- Copy pixel (xs, ys) from the source to (x, y) in the destination
    		--a = "Doing destY " .. destY .. " destX " .. destX .. " ys " .. ys .. " xs " .. xs
			if (xs <= width and ys <= height and xs > 0 and ys > 0) then
				newImageData[destY+colourHeaders+1] = newImageData[destY+colourHeaders+1] .. string.sub(imageData[ys+colourHeaders+1],xs,xs)
			else
				newImageData[destY+colourHeaders+1] = newImageData[destY+colourHeaders+1] .. " "
			end
		end
	end
	return newImageData
end

fltk.fl_register_images()
fileName = fltk.fl_file_chooser("Choose a picture", "Image Files (*.{xpm,gif})", "../images", nil)
image1 = Fl_Shared_Image.get(fileName)
test = image1:data()

window = fltk:Fl_Window(435, 145, "Pixmap rotation test");

button1 = fltk:Fl_Button(5, 5, 210, 135, "Original Picture");
button2 = fltk:Fl_Button(220, 40, 210, 100, "Rotated Picture");

slider = fltk:Fl_Slider(220, 10, 210, 20, "");
slider:type(1)
slider:range(0, 360)
slider:step(1)
slider:value(0)

button1:image(image1)
test2 = pixMapRotate(image1, 0)
image2 = fltk:Fl_Pixmap(test2)

-- button2:image(image2)

slider:callback(
	function(slider)
		test2 = pixMapRotate(image1, slider:value())
		image2 = fltk:Fl_Pixmap(test2)
		button2:image(image2)
		button2:label("Rotation angle : " .. slider:value())
		button2:redraw()
	end)
	
window:show()
Fl:run()
