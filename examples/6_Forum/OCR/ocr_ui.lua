-- FANN number recognition

-- Todo, refactor so: 
-- 1) DONE only 6 boxes (or 7 as in a led 7 segment display)
-- 2) DONE draw lines, and each box gets a weight ~ (number of dots in box / total number of dots)
-- 3) optional: Add keeping of number of strokes
-- 4) optional: track general direction in box.
-- results => 6 or 12 dimensions per char instead of 100

-- TODO's aside of those:
-- * DONE option to save training data.
-- * Make lines disconnect after mouse button release.
-- * make previews work.
-- * training counter at each preview
-- * transform to scale, rotate and center character drawn.


num_samp = 3
function table.sum(t)
	local result=0
	for k=1,#t do
		result=result+t[k]
	end
	return result
end

function normalize(boxes)
	totalDots=table.sum(boxes)
	for k=1,#boxes do
		boxes[k]=math.floor(boxes[k]/totalDots*100)
	end
	return boxes
end
-- Declaration of global variables
make_window = make_window or nil
draw = draw or nil
function reset_current() -- only reset current character data, and drawing
	win:make_current()
	fltk.fl_color(fltk.FL_WHITE)
	fltk.fl_rectf(20,45,120,180)
	boxes={}					-- wipe boxes
	for k=1,6 do boxes[k]=0 end --initialize at 0
	lastX,lastY=nil,nil
end

function reset()
	reset_current()
	data={}
	print(trainingdata)
	if trainingdata then os.remove(trainingdata)end
	trainingdata=os.tmpname()
end

do -- training state machine -1(init) -> 0 x3 -> 1 x3 ... -> 9 x3 -> write training & train --\
--                            ^---------------------------------------------------------------/
local state,try=-1,1
	function train()
		print("Train",state,try)
		if state<0 then
			fltk.fl_alert('Now write number the numbers from 0 to 9, and press this button after each one')
			state=0
			train_but:label("Learn "..state)
			net=fann.Net.create_standard({6,10,9}) -- create the neural net
			data[1]="" -- to make next line work
			data[1]=#data+10*num_samp-1 .." 6 10" -- enables updating training (6 features, 10 classes)
		elseif state <= 9 then
			local t={}
			local totalDots
			boxes=normalize(boxes)
			t.input=table.concat(boxes," ") -- inputs
			t.output=("0 "):rep(state).."1 "..("0 "):rep(9-state) --outputs (= dirac_class(x))
			print(t.input)
			data[#data+1]=t -- save table
			-- Wipe boxes visually and in data.
			reset_current()
			-- Draw some mean of the data as a preview.
			if try==num_samp then 
				try=1
				state=state+1
				if state==10 then
					train_but:label("Finish")
				else
					train_but:label("Learn "..state)
				end
			else
				previews[state+1]:label(previews[state+1]:label():gsub("(%d+)$",try))
				try=try+1
			end
		else -- 10
			--	make tempfile, write data
			local fh,err=io.open(trainingdata,"w")
			if not fh then
				error(err)
			end
			for k,v in pairs(data) do
				if type(v)=="string" then -- header
					fh:write(v,"\n")
				else
					fh:write(v.input,"\n",v.output,"\n\n")
				end
			end
			fh:close()
			-- do training
			print("Training result:",net:train_on_file(trainingdata,20000,10,0.001)) -- data, max_iter,classes, accuracy
			-- reset label
			train_but:label("Train")
			-- reset state
			state=-1
		end
	end
end

function detect() -- TODO revise
	local boxes=normalize(boxes)
	local output = {net:run(unpack(boxes))}
	reset_current()
	local max,sec,id1,id2=0,0,0,0
	for k=1,#output do
		if output[k]>max then sec=max id2=id1 max = output[k] id1=k end
	end
	fltk.fl_alert("Detected "..(id1-1).." with a confidence of "..max.."\n(second "..(id2-1).." at "..sec)
end

function safe_detect()
	print(pcall(detect))
end

function draw_boxes(lastX,lastY)
	win:make_current()
	fltk.fl_color(fltk.FL_BLACK)
	fltk.fl_font(fltk.FL_HELVETICA_BOLD,20)
	for k=0,1 do
		for l=0,2 do
			local tlx,tly,brx,bry=20+k*60,45+l*60,60,60
			if Fl:event_inside(tlx,tly,brx,bry)==1 then
				boxes[k*3+l+1]=boxes[k*3+l+1]+1
			end
		end
	end
	local curX,curY=Fl:event_x(),Fl:event_y()
	if lastX and lastY then
		fltk.fl_line(lastX,lastY,curX,curY)
	end
	return curX,curY
end

function draw_loop(data)
	if Fl:event() == fltk.FL_DRAG and Fl:event_inside(draw)==1 then
		lastX,lastY=draw_boxes(lastX,lastY)
		print'Drag'
	end
	if Fl:event() == fltk.FL_RELEASE then
		lastX,lastY=nil,nil
		print'release'
	end
	Fl:check()
	timer:doWait(0.01)
end

function save(self)-- TODO Test
	local fileName = fltk.fl_file_chooser("Save as","FANN Net(*.net)","Numberrecognition.net"),nil
	if fileName then
		local testwrite=io.open(fileName,"w")
		if testwrite then
			if net then
				testwrite:close()
				net:save(fileName)
			else
				fltk.fl_alert("No net to save!")
			end
		else fltk.fl_alert("Can't write to "..fileName)
		end
	end
end

function open(self)-- TODO Test
	local fileName = fltk.fl_file_chooser("Open neural net","FANN Net(*.net)","Numberrecognition.net"),nil
	if fileName then
		net,err = fann.Net.create_from_file(fileName)
		if not net then
			fltk.fl_alert("Error loading net from "..fileName..": "..err)
		end
	end
end

function loadTraining(self)
	local fileName = fltk.fl_file_chooser("Load training data","Text(*.txt)","training.txt"),nil
	if fileName then
		net,err = fann.Net.create_standard({6,10,9})
		print("Training result:",net:train_on_file(fileName,20000,10,0.001))
	end
end

function saveTraining(self)-- TODO Test
	local data
	if lfs.attributes(trainingdata,'mode')~='file' then
		fltk.fl_alert("Error saving training data: No training data available")
		return
	else
		local fhin=io.open(trainingdata,'rb')
		data=fhin:read('*a')
	end
	local fileName = fltk.fl_file_chooser("Save training data as","Text(*.txt)","training.txt"),nil
	if fileName then
		local fhOut=io.open(fileName,"wb")
		if fhOut then
			fhOut:write(data)
			fhOut:close()
		else
			fltk.fl_alert("Can't write to "..fileName)
		end
	end
end

function quit(self)
	if fltk.fl_choice("Really exit?","No","Yes",NULL) then
		local fh=io.open(trainingdata)
		if trainingdata and fh then
			fh:close()
			os.remove(trainingdata)
		end
		os.exit()
	end
end

function make_window()
	win = fltk:Fl_Double_Window(335, 172, 630, 300, "FANN Number recognition Demo")
	win:callback(quit)
    draw = fltk:Fl_Box(20, 45, 120, 180, "Drawing area")
	draw:color(55)
	draw:align(5)
	draw:box(fltk.FL_FLAT_BOX)
	-- detection boxes.
	for k=0,9 do
		o=fltk:Fl_Box(180+90*math.fmod(k,5), 45+140*math.floor(k/5), 60, 90, tostring(k).." - 0")
		o:box(fltk.FL_FLAT_BOX)
		o:color(55)
		o:align(5)
		previews[#previews+1]=o
	end

	local o = fltk:Fl_Button(5, 230, 65, 25, "Reset")
	o:callback(reset)
	train_but = fltk:Fl_Button(90, 230, 65, 25, "Train")
	train_but:callback(train)
	local o = fltk:Fl_Button(5, 260, 65, 24, "Detect")
	o:callback(safe_detect)
	--local o = fltk:Fl_Button(90, 260, 65, 25, "Load Training")
	--o:callback(load_training)
    local o = fltk:Fl_Menu_Bar(0, 0, 670, 25, "Menu")
    do
      o:add("File/Open Net",nil,open)
      o:add("File/Save Net",nil,save)
	  o:add("File/Load Training Data",nil,loadTraining)
	  o:add("File/Save Training Data",nil,saveTraining)
      o:add("File/Quit", nil,quit)
	  o:add("Help")
    end
  win['endd'](win)
  return win
end

previews={}-- TODO revise
for _,i in ipairs {make_window()} do i:show() end
reset()
timer = murgaLua.createFltkTimer()
timer:callback(draw_loop)
timer:do_callback()
Fl:run()
