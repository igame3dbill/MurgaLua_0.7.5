#!/usr/bin/env murgaLua
-- a test: mimic a 3D model turntable
-- 2011 mikshaw

dir = "frames/"

fltk.fl_register_images()
images = {}
temp = {}
timer = murgaLua.createFltkTimer()

-- add filenames to temp table and sort
for filename in lfs.dir(dir) do
    table.insert(temp, dir..filename)
end
table.sort(temp)

for i, v in pairs(temp) do
    tmp = Fl_Shared_Image.get(v)
    if tmp then
        table.insert(images, tmp)
    end
end

width = images[1]:w()
height = images[1]:h()
w=fltk:Fl_Double_Window(width,height,"Turntable")
box=fltk:Fl_Box(0,0,width,height)
frame = 1
box:image(images[frame])
function prevframe ()
    if frame == 1 then frame = table.maxn(images)
    else frame = frame - 1 end
    box:image(images[frame])
    box:redraw()
end
function nextframe()
    if frame == table.maxn(images) then frame = 1
    else frame = frame + 1 end
    box:image(images[frame])
    box:redraw()
end

function loop()
if Fl:event_button() > 0 and Fl:event() == fltk.FL_DRAG then
    if Fl:event_button() == 1 then
        -- reverse direction with mouse 2 or 3
        fwd = nextframe
        rev = prevframe
    else
        fwd = prevframe
        rev = nextframe
    end
    new_pos = Fl:event_x()
    -- 8-pixel frame change threshold
    if new_pos > old_pos + 8 then fwd()
    elseif new_pos < old_pos - 8 then rev()
    end
else old_pos = Fl:event_x()
end
timer:doWait(0.025)
end

timer:callback(loop)
timer:do_callback()
w:show()
Fl:run()
