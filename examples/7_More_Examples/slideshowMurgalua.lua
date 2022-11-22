-- simple image viewer
-- mikshaw 2007
-- inspired by the work of john murga
-- requires murgaLua version 0.5 or greater

--dir="./" -- default image directory in unix see updated dir below
pause=5 -- seconds between slideshow images
ss=0 -- slideshow 1=on 0=off
fs=0 -- fullscreen
bg=0 -- background color

images = {}
imageList = {}

cDirectory=lfs.currentdir()

function listFolders(path)
local folderList=""
    for file in lfs.dir(path) do
        
        if file ~= "." and file ~= ".." then
            local f = path..'/'..file
            local attr = lfs.attributes (f)
            assert (type(attr) == "table")
             if attr.mode == "directory" then 
               
             folderList=folderList..file.."\n"
             end   
        end
    end
    return folderList
end

function listFiles(path, t)
local fileList=""
    for file in lfs.dir(path) do
        if file ~= "." and file ~= ".." then
            local f = path..'/'..file
            local attr = lfs.attributes (f)
            assert (type(attr) == "table")
             if attr.mode == "file" then 
              fileList=fileList..file.."\n"
			  table.insert(images,file)
              end   
        end
    end
	print(t)
	if t == "table" then 
	return images
	else
    return fileList
	end
end

--dir="./pix/" -- ending slash is vital ..this was for unix systems
ipath = "\\images\\"
dir = cDirectory..ipath -- ending slash is vital
images = listFiles(dir,"table")  
--images = murgaLua.readDirectory(dir) --  deprecated at some point

-- Check for commandline arguments
for i=1,table.getn(arg) do
if arg[i] == "-s" then ss=1 end --activate slideshow
if arg[i] == "-f" then fs=1 end --force fullscreen ("f" to toggle)
if arg[i] == "-l" then ls=1 end --show file list {"l" to toggle)
if arg[i] == "-d" and murgaLua.isDirectory(arg[i+1]) then dir=arg[i+1] end --specify a directory
if arg[i] == "-bg" then bg=arg[i+1] end --specify a background color
end

fltk.fl_register_images()
allfiles = listFiles(dir,"table")   --murgaLua.readDirectory(dir)
table.sort(allfiles)
images = {}
-- use only image files
for i=1,table.getn(allfiles) do
-- hoping there's a simpler way to do this
tempstring=string.lower(allfiles[i])
if string.find(tempstring,"%.png$") or
string.find(tempstring,"%.jpe?g$") or
string.find(tempstring,"%.bmp$") or
string.find(tempstring,"%.p[bgnp]m$") or
string.find(tempstring,"%.x[bp]m$") or
string.find(tempstring,"%.gif$")
then table.insert(images,allfiles[i]) end
end
--os.exit()
Fl:visible_focus(0)
ww=Fl:w();wh=Fl:h()
imgnum=0
fwd=1

timer=murgaLua.createFltkTimer()
function exit()
--confirm=fltk.fl_choice("sure you want to quit?","no","yes",NULL)
--if confirm == 1 then
print("goodbye"); os.exit(0)
--end
end

function toggle_fullscreen()
if fs==1 then
w:fullscreen_off(ww/2-active_image:w()/2,wh/2-active_image:h()/2,active_image:w(),active_image:h())
fs=0
else w:fullscreen(); fs=1
end
display:size(w:w(),w:h())
end

function zoomin()
zoom_image=active_image:copy(ww,wh)
display:image(zoom_image)
w:resize(0,0,ww,wh)
display:size(ww,wh)
display:redraw()
end
function zoomout()
display:image(active_image)
if fs==0 then fs=1; toggle_fullscreen() end
display:redraw()
end

function toggle_list()
if ls==1 then ls=0; fw:hide() else ls=1; fw:show() end
end

function show_image()
active_image=Fl_Shared_Image.get(dir.."/"..images[imgnum])
if active_image then
if fs==0 then fs=1; toggle_fullscreen() end --reusing toggle_fullscreen to resize window to image size
display:image(active_image)
else next_image()
end
list:value(imgnum)
display:redraw()
end

function next_image()
if fwd == 0 then
if imgnum <= 1 then imgnum=table.getn(images) else imgnum = imgnum-1 end
else
if imgnum >= table.getn(images) then imgnum=1 else imgnum = imgnum+1 end
end
show_image()
if ss==1 then timer:doWait(pause) end
end

function button_cb()
if Fl:event_button() == fltk.FL_RIGHT_MOUSE or Fl:event_key() == fltk.FL_Page_Up then fwd=0 else fwd=1 end
if Fl:event_button() == fltk.FL_MIDDLE_MOUSE then
toggle_fullscreen()
else    next_image()
end
end


w=fltk:Fl_Double_Window(ww,wh,"MurgaLua Image Viewer")
buttons={}
for i=1,5 do buttons[i]=fltk:Fl_Button(0,0,0,0) end
display=fltk:Fl_Button(0,0,ww,wh)
display:box(1);display:color(bg)
if ss==1 then
display:callback(exit)
timer:callback(next_image)
else
display:shortcut(fltk.FL_Page_Down); display:callback(button_cb);
buttons[1]:shortcut(fltk.FL_Page_Up); buttons[1]:callback(button_cb)
buttons[2]:shortcut(fltk.FL_Up); buttons[2]:callback(zoomin)
buttons[3]:shortcut(fltk.FL_Down); buttons[3]:callback(zoomout)
buttons[4]:label("&fullscreen"); buttons[4]:callback(toggle_fullscreen)
buttons[5]:label("&list"); buttons[5]:callback(toggle_list)
end
fltk.Fl_End()


fw=fltk:Fl_Window(0,0,ww/4,wh/3)
list=fltk:Fl_Hold_Browser(2,2,ww/4-4,wh/3-4) -- file list
fltk.Fl_End()
function choose_image()
imgnum=list:value()
show_image()
end
list:callback(choose_image)
for i=1,table.getn(images) do list:add(images[i]) end

w:callback(exit)
w:show()
if ls==1 then fw:show() end
next_image()

Fl:run()

