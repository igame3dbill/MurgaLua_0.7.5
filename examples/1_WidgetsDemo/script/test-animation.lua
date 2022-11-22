-- image sequence animation demo
-- mikshaw 2007
-- Reworked by John Murga
-- Reworked again by mikshaw for murgaLua 0.5.5

-- IMPORTANT: images is set from the main script

playMode=false
frameCount=0

timer = murgaLua.createFltkTimer()

frame={} -- 
fltk.fl_register_images()

for i in lfs.dir(images) do
  findPng=string.find(i,"fish%d%.png$")
  if findPng ~=nil  then
    img=Fl_Shared_Image.get(images..i)
    frame[frameCount]=img 
    io.flush()
    frameCount=frameCount+1 
  end
end


function play_button(data)
  playMode = not playMode
  if playMode==true then
    playbutton:label("stop")
    currentFrame =0;
    timer:doWait(frameControl:value())
  else
    playbutton:label("play")
    timer:doWait(0)
  end
end

function sleep_callback(data)
  currentFrame=currentFrame+1;
  if currentFrame >= frameCount then
    currentFrame = 0
  end
  
  display:image(frame[currentFrame]:copy(80,80)) 
  display:redraw()
  Fl:check()
  timer:doWait(frameControl:value())
end


w=fltk:Fl_Double_Window(120,160,"Image Sequence Animation Demo")

display=fltk:Fl_Box(20,20,80,80)
display:box(1);display:color(fltk.FL_BLACK)
display:image(frame[0])
playbutton=fltk:Fl_Button(20,100,80,20,"play")
frameControl=fltk:Fl_Spinner(50,120,50,20,"spd")

frameControl:type (fltk.FL_FLOAT_INPUT)
frameControl:range(0.01,1)
frameControl:value(0.10)
frameControl:step (0.01)

playbutton:callback(play_button)
timer:callback(sleep_callback)

w:show()
Fl:run()
