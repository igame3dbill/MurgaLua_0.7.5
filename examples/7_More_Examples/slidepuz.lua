-- jigsaw-like puzzle for MurgaLua 0.6.4+
-- 2011 mikshaw

ts = 64 --tile size

function err(e,r)
if fltk then fltk.fl_alert(e) else print(e) end
os.exit(r)
end

if not Fl_Image.getTiles then
err("This program requires murgaLua 0.6.4 or newer.\n\n"..
    "http://www.murga-projects.com/murgaLua/index.html", 1)
end

fileName = arg[1] -- if filename given as cmdline argument
-- browse for file
fltk.fl_register_images() -- do this early so chooser can show preview
if not fileName then
fileName = fltk.fl_file_chooser("Choose an RGB image", "Image Files (*.{jpg,png,bmp,xbm,xpm,gif})", nil, nil)
end
if not fileName then
err("Please supply an image filename.\nUse: "..
    fltk.fl_filename_name(arg[0]).." \"filename\"\n"..
    "or select an image with the file chooser." , 2)
end

-- check image
img = Fl_Shared_Image.get(fileName)
if not img then err("Could not open "..fileName, 3) end
iw = img:w(); ih = img:h()

-- try to find a balance between image size and tile size
if iw % ts == 0 and ih % ts == 0 then
  tw, th = ts, ts
  cols = iw / ts
  rows = ih / ts
else
  cols = math.floor(iw / ts)
  rows = math.floor(ih / ts)
  tw = math.floor(iw / cols)
  th = math.floor(ih / rows)
  iw = cols * tw
  ih = rows * th
end

if murgaLua.getHostOsName() =="windows" then
  save_dir = os.getenv("USERPROFILE").."\\.luapuzzle\\"
else
  save_dir = os.getenv("HOME").."/.luapuzzle/"
end
save_file = save_dir..fltk.fl_filename_name(fileName)..".save"

function save_me()
local confirm = fltk.fl_choice("Do you want to save this puzzle?", "no", "yes", NULL)
if confirm == 1 then
  lfs.mkdir(save_dir)
  local outpoot = io.open(save_file,"w")
  if outpoot then
    pausetime = os.time() - starttime
    outpoot:write("m"..moves.."\np"..pausetime.."\n")
    for i,_ in pairs(tile) do
      outpoot:write("t"..i.." ".."x"..tile[i]:x().." ".."y"..tile[i]:y().."\n")
      --outpoot:write("tile["..i.."]:position("..tile[i]:x()..","..tile[i]:y()..")\n")
    end
    outpoot:close()
    fltk.fl_message("puzzle saved to\n"..save_file)
  else fltk.fl_message("sorry I can't write to "..save_file)
  end
end
end

function load_me()
local confirm = fltk.fl_choice("Try to retrieve saved puzzle?", "no", "yes", NULL)
if confirm == 1 then
  local test = io.open(save_file,"r")
  if test then
    test:close()
    for line in io.lines(save_file) do
      if string.find(line, "^t%d+%sx%d+%sy%d+$") then
        local t = string.gsub(line,".*t(%d+).*","%1")
        local x = string.gsub(line,".*x(%d+).*","%1")
        local y = string.gsub(line,".*y(%d+).*","%1")
        tile[tonumber(t)]:position(tonumber(x),tonumber(y))
      elseif string.find(line, "^m%d+$") then 
        local m = string.gsub(line, "^m", "")
        moves = tonumber(m)
      elseif string.find(line, "^p%d+$") then 
        local p = string.gsub(line, "^p", "")
        if not starttime then starttime = os.time() end
        starttime = starttime - p
      end
    end
    win:redraw()
  else fltk.fl_message("no save file available")
  end
end
end

function set_tile_images()
  -- crop the image to iw,ih 
  img_data = img:data()
  collectgarbage()
  offScreenBuffer = murgaLua.createOffscreenBuffer(iw, ih)
  offScreenBuffer:startOffScreenDrawing()
  -- On Linux we have to clear the buffer (not on Mac or Win32)
  fltk.fl_color(0)
  -- Linux will segfault unless we set the font before using fl_draw
  fltk.fl_font(0)
  if img:count() > 2 then data = img_data else data = img_data[1] end
  fltk.fl_draw_image(data, 0, 0, img:w(), img:h(), 3)
  image = offScreenBuffer:getOffScreenImage()
  -- tile it up
  for i,_ in pairs(tile) do
    tileString = fltk.fl_read_image(pos[i].col, pos[i].row, tw, th)
    tile[i]:image(fltk:Fl_RGB_Image(tileString, tw, th, 3, 0))
  end
  offScreenBuffer:endOffScreenDrawing()
  please_wait:hide()
  box:image(image)
  box:hide()
save_puzzle:shortcut("s")
load_puzzle:shortcut("l")
preview:shortcut("p")
end

function scramble()
math.randomseed(os.time())
for scram = 1, 10000 do
  local a = math.random(0, rows * cols - 1)
  tile_A_x = tile[a]:x(); tile_A_y = tile[a]:y()
  local b = math.random(0, rows * cols - 1)
  tile[a]:position(tile[b]:x(), tile[b]:y())
  tile[b]:position(tile_A_x, tile_A_y)
end
end

function secondsToClock(sSeconds)
-- TJ_Tigger from http://www.indigorose.com/forums/archive/index.php/t-14669.html
local nSeconds = tonumber(sSeconds)
if nSeconds == 0 then
return "00:00:00";
else
nHours = string.format("%02.f", math.floor(nSeconds/3600));
nMins = string.format("%02.f", math.floor(nSeconds/60 - (nHours*60)));
nSecs = string.format("%02.f", math.floor(nSeconds - nHours*3600 - nMins *60));
return nHours..":"..nMins..":"..nSecs
end
end

function drag_loop()
  if inplay == 1 then
    drag_box:position(Fl:event_x() - tw / 2, Fl:event_y() - th / 2)
    win:redraw()
  end
  drag_timer:doWait(.02)
end

function isitfinish()
for i = 0, rows * cols - 1 do
  if tile[i]:x() ~= pos[i].col or tile[i]:y() ~= pos[i].row then
  return end
end
for i,_ in pairs(tile) do
  tile[i]:hide()
end
preview:hide()
box:show()
if not seconds then
  seconds = os.time() - starttime
  fltk.fl_message("time: "..secondsToClock(seconds).."\n"..moves.." moves")
end
end

function move_tile(t)
if inplay == 0 then
  if not starttime then
    starttime = os.time()
  end
  inplay = 1
  drag_box:show()
  from_t, from_x, from_y = t, t:x(), t:y()
  drag_box:image(t:image())
  t:labeltype(fltk.FL_NO_LABEL)
  t:box(fltk.FL_DOWN_BOX)
else
  inplay = 0
  from_t:labeltype(fltk.FL_NORMAL_LABEL)
  from_t:box(fltk.FL_NO_BOX)
  if from_t:x() ~= t:x() or from_t:y() ~= t:y() then
    from_t:position(t:x(),t:y())
    t:position(from_x, from_y)
    moves = moves + 1
  end
  drag_box:hide()
  win:redraw()
  isitfinish()
end
end

fs, moves, starttime, seconds = 0, 0, nil, nil
Fl:visible_focus(0)
timer = murgaLua.createFltkTimer()
timer:callback(set_tile_images)


win = fltk:Fl_Double_Window(iw,ih, fltk.fl_filename_name(fileName))

tile = {}; pos = {}
row = 0; col = 0
-- -1 is used because the number of tiles starts at 1
-- but table starts at 0 (easier to position them from zero)
for i = 0, rows * cols - 1 do
  tile[i] = fltk:Fl_Button(col,row,tw,th)
  tile[i]:box(fltk.FL_NO_BOX)
  tile[i]:align(80)
  tile[i]:callback(move_tile)
  pos[i]={col=col, row=row} 
  col = col + tw
  -- start the next row
  if col == iw then col = 0; row = row + th end
end

drag_box = fltk:Fl_Box(0,0,tw,th)
drag_box:hide()
drag_timer = murgaLua.createFltkTimer()
drag_timer:callback(drag_loop)
drag_timer:do_callback()
inplay = 0

save_puzzle = fltk:Fl_Button(-10, -10, 1, 1)
save_puzzle:callback(save_me)
load_puzzle = fltk:Fl_Button(-10, -10, 1, 1)
load_puzzle:callback(load_me)
preview = fltk:Fl_Button(-10,-10,1,1)
preview:callback(
function()
if box:visible() == 1 then box:hide() else box:show() end
end
)

if iw <= Fl:w() and ih <= Fl:h() then
fullscr = fltk:Fl_Button(-10,-10,1,1)
fullscr:shortcut("f")
fullscr:callback(
function()
if fs == 0 then
  fs = 1
  wx, wy = win:x(), win:y()
  win:fullscreen()
else
  fs = 0
  win:resize(wx,wy,iw,ih)
end
end
)
end

box = fltk:Fl_Box(0,0,iw,ih)
box:image(img)
fltk.fl_define_FL_EMBOSSED_LABEL()
please_wait = fltk:Fl_Box(0,0,iw,ih, "SCRAMBLE IN PROGRESS.\nplease wait...")
please_wait:align(149)
please_wait:labeltype(4)
please_wait:labelfont(1)
please_wait:labelsize(20)
win:show()
timer:doWait(1)
scramble()
Fl:run()