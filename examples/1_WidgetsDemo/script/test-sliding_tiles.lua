-- window size is determined by the following variables
ts=48 -- tile size
tc=4  -- number of tiles in one line
fr=5 -- frame size

function move_tile(t)
  local my_x,my_y,movex,movey=t:x(),t:y()
  -- tile must be adjacent to the missing piece
  if (my_x == tile[hidden]:x() and math.abs(my_y-tile[hidden]:y()) == ts)
  or (my_y == tile[hidden]:y() and math.abs(my_x-tile[hidden]:x()) == ts)
  then
    movex=tile[hidden]:x()
    movey=tile[hidden]:y()
    tile[hidden]:position(my_x,my_y)
    t:position(movex,movey)
    w:redraw()
  end
  if not start then -- don't check puzzle during scramble
  local ok=0
  for i=0,tc*tc-1 do
    if tile[i]:x()==pos[i].col and tile[i]:y()==pos[i].row then
      ok=ok+1
    if ok==tc*tc then
      tile[hidden]:box(fltk.FL_UP_BOX)
      tile[hidden]:label(hidden+1)
      fltk.fl_beep()
      message:label(prize[math.random(1,table.getn(prize))])
      for i=0,tc*tc-1 do tile[i]:set_output() end
      break
    end
    end
  end
  end
end

function scramble()
-- this picks a random tile to attempt to move and
-- repeats the process many times. Simply placing
-- tiles in random locations could potentially make
-- the puzzle impossible to solve
local scram=0
while scram < 10000 do
  move_tile(tile[math.random(0,tc*tc-1)])
  scram=scram+1
end
w:redraw()
end

prize={"Great Job!", "Hooray for You!", "You don't suck!", "WIN!", "GODLIKE!"}

Fl:visible_focus(0)
Fl:set_boxtype(fltk.FL_UP_BOX,fltk.FL_THIN_UP_BOX)
Fl:set_boxtype(fltk.FL_DOWN_BOX,fltk.FL_THIN_DOWN_BOX)
w=fltk:Fl_Window(ts*tc+fr*2,ts*(tc+0.5)+fr*3,"slide puzzle")
message=fltk:Fl_Box(fr,ts*tc+fr*2,ts*tc,ts/2)

-- array of tiles, top left to right, then move down
tile={}; pos={}
-- allow space for the frame
row=fr; col=fr
-- subtract one is used because the number of tiles starts at one
-- but the table starts at zero (easier to position them from zero)
for i=0,tc*tc-1 do
  tile[i]=fltk:Fl_Button(col,row,ts,ts)
  tile[i]:callback(move_tile)
  tile[i]:label(i+1) -- simple numbers could be replaced by images
  pos[i]={col=col,row=row}
  -- next piece is ts pixels to the right
  col=col+ts
  -- start the next row
  if col == ts*tc+fr then col=fr;row=row+ts end
end

-- turn a random tile into the missing piece
math.randomseed(os.time())
hidden=math.random(0,tc*tc-1)
tile[hidden]:label("")
tile[hidden]:box(fltk.FL_DOWN_BOX)

w:show()
start=1
scramble()
start=nil
Fl:run()
