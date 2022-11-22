-- random squares drawn offscreen with murgaLua

math.randomseed(os.time())
-- these values will depend on the project
offscreenHeight, offscreenWidth  = 320, 320

-- these values are used against copy() and are randomized later in this script.
redrawHeight , redrawWidth  = 200, 200 

-- counter values keep track of the color cycling on the random filled rects
colorcounter, basecounter, counterStep, counterLimit = 0 ,1, 7, 255

-- if the quads are larger than the grid there will be overlap
gridSize , quadSize = 8, 8  


function random_colorsquares()
-- cycle colors
    colorcounter = colorcounter + counterStep
    if colorcounter > counterLimit then colorcounter = counterStep end
    fltk.fl_color(basecounter + colorcounter)   
-- randomized quadsize
    local Rs = math.random(quadSize-15,quadSize)
    
 -- distance from center on each side of the quad   
    local quadHalf = math.floor(Rs/2)
    
    -- find a Random Point in the buffer 
    local Rx, Ry = math.random(1,offscreenHeight) ,  math.random(1,offscreenWidth)
    
    -- match x,y to a valid point based on grid size 
    local Px = (math.floor((Rx+(quadSize/2))/gridSize)*gridSize)-1
    local Py = (math.floor((Ry+(quadSize/2))/gridSize)*gridSize)-1
    
    -- find the top left corner of the new quad
    local Left,Top = Px-quadHalf, Py-quadHalf
    -- draw the filled rectangle
	fltk.fl_rectf(Left , Top ,Rs,Rs) 
end   




 
function offScreenDraw(w)
    collectgarbage()
    offScreenBuffer = murgaLua.createOffscreenBuffer(offscreenWidth , offscreenHeight)
    offScreenBuffer:startOffScreenDrawing()    
  -- On Linux we have to clear the buffer (not on Mac or Win32)
    fltk.fl_color(0)
  -- Linux will segfault unless we set the font before using fl_draw
     --fltk.fl_font(fltk.FL_HELVETICA_BOLD,14)
     --fltk.fl_draw("OffScreen Drawing",10,20) 
  -- the offscreen bufffer is now ready for input on all platforms
 
  -- some random colored squares
     for i = 1 , 2048 do random_colorsquares() end
       
  -- randomized redraw height for fun
     local rH , rW = math.random(redrawHeight,redrawHeight*4) ,  math.random(redrawWidth,redrawWidth*4)
  
  -- the offscreen buffer can be copied and resized
     imageData = offScreenBuffer:getOffScreenImage():copy(redrawHeight,redrawHeight)
     redrawbuffersize = redrawHeight*redrawHeight*4
    p={}
    p[redrawbuffersize]=0
       --alphaimage = fltk.fl_read_image(imageData, 0,0, redrawHeight , redrawHeight, 255)
    --print(alphaimage)

      -- end the off screen drawing
      offScreenBuffer:endOffScreenDrawing()
       getOffScreen_Button:image(imageData)
    getOffScreen_Button:redraw()
      end
       

    
     
        
  
  --resizeimage = alaphaimage:copy(redrawHeight,redrawHeight)
  -- insert the offscreen buffer as image data of an object


  
  do local object = fltk:Fl_Double_Window(210, 210, "OffScreen drawing");
    window = object;
    do getOffScreen_Button = fltk:Fl_Button(5, 5, 200, 200, "Get off screen image");
    end -- Fl_Button* getOffScreen
  end
  
  getOffScreen_Button:callback(offScreenDraw);

  window:show();
 -- Fl:run();
--loop=offScreenDraw()



while not Fl:event_key()   do
Fl:wait(0)
    Fl:check()
     getOffScreen_Button:do_callback()
end
