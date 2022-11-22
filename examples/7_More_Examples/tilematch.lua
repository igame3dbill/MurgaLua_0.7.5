-- concentration
-- 2011 mikshaw

ts = 100 -- tile size
cols = 8 -- number of horizontal tiles
rows = 6 -- vertical tiles
img_dir = "images\\"   -- file path when in root of  program. note double slash escape characters for Windows

function tile_cb(self)
self:labeltype(fltk.FL_NORMAL_LABEL)
if not first_tile then first_tile = self
else
  moves = moves + 1
  if first_tile:tooltip() == self:tooltip() then
    first_tile:set_output()
    self:set_output()
    active = active - 2
    if active == 0 then fltk.fl_alert(moves.." moves") end
  else
    Fl:check()
    murgaLua.sleep(500)
    self:labeltype(fltk.FL_NO_LABEL) 
    first_tile:labeltype(fltk.FL_NO_LABEL) 
    win:redraw()
  end
first_tile = nil
end
end

used_numbers = "x"
function unique_random()
math.randomseed(os.time())
local rand = math.random(0, rows * cols - 1)
-- try again if number is already used
while string.find(used_numbers, "x"..rand.."x") do
rand = math.random(0, rows * cols - 1)
end
-- save used numbers in a string
used_numbers = used_numbers..rand.."x"
return rand
end

win = fltk:Fl_Double_Window(ts * cols , ts * rows, "Memory Game")

tile = {}
r, c = 0, 0 -- row and column positions
for i = 0, rows * cols - 1 do
  tile[i] = fltk:Fl_Button(c, r, ts, ts)
  tile[i]:align(80)
  tile[i]:callback(tile_cb)
  c = c + ts
  -- start the next row
  if c == win:w() then c = 0; r = r + ts end
end

fltk.fl_register_images()

-- apply images to random tiles
-- two copies of each image
count = 0
img = {}
for file in lfs.dir(img_dir) do
  if count < cols * rows / 2 then -- stop grabbing images after tiles are filled
    img_check = Fl_Shared_Image.get(img_dir..file)
    if img_check then
      img[count] = img_check
      local first = unique_random() -- first instance of the image
      tile[first]:image(img[count])
      tile[first]:tooltip(file)
      tile[first]:labeltype(fltk.FL_NO_LABEL)
      local second = unique_random() -- second instance
      tile[second]:image(img[count])
      tile[second]:tooltip(file)
      tile[second]:labeltype(fltk.FL_NO_LABEL)
      count = count + 1
    end
  else break
  end
end

moves = 0
active = rows * cols
Fl_Tooltip:disable() -- tooltip values are used only to compare tiles
win:show()
Fl:run()