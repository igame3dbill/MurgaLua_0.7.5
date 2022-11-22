-- This used to display png and gif images in $HOME/.xtdesktop
-- Code by mikshaw (http://damnsmalllinux.org/cgi-bin/forums/ikonboard.cgi)
-- updated 09 12 2021 to display images in "images" folder in current directory
-- changed for windows and replaced deprecated murgaLua.readdirectory

ww=400 --window width
wh=350 --window height

images = {}
imageList = {}



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
cDirectory=lfs.currentdir()
--dir="./pix/" -- ending slash is vital ..this was for unix systems
ipath = "\\images\\"
dir = cDirectory..ipath -- ending slash is vital
images = listFiles(dir,"table")  
-- images = murgaLua.readDirectory(dir) --deprecated
fltk.fl_register_images()

function get_image_data(self)
  for i=1,table.getn(images) do
    if self:tooltip() == dir..images[i] then -- find the right image
      display:image(icon[i]:copy(128,128)) --show it bigger!
      display_label:label(images[i].."\n"..icon[i]:w().."x"..icon[i]:h()) -- show height and width
      display:redraw()
      break
    end
  end
end

w=fltk:Fl_Window(ww,wh,"murgaLua Gif/Png Icon Demo")
w:color(42)

display=fltk:Fl_Box(120,30,256,256) -- big image
display_label=fltk:Fl_Box(120,290,256,40)
display_label:label("nothing")
display:box(fltk.FL_THIN_DOWN_BOX)
display:color(55)

scroll=fltk:Fl_Scroll(5,5,90,330)
scroll:color(55)
pack=fltk:Fl_Pack(5,5,68,300)
pack:spacing(2)
icon={}; butt={}
row=1;col=1
-- since the images table contains more than just images (*.lnk gets in too)
-- i'm building the icons from specific items in the table.
for i=1,table.getn(images) do
  if string.find(images[i],".png",-4,plain) or string.find (images[i],".gif",-4,plain)
  then
    icon[i]=Fl_Shared_Image.get(dir..images[i])
    butt[i]=fltk:Fl_Button(0,0,64,64)
    butt[i]:align(fltk.FL_ALIGN_CLIP)
    butt[i]:image(icon[i])
    butt[i]:tooltip(dir..images[i])
    butt[i]:callback(get_image_data)
    butt[i]:color(55)
    butt[i]:box(fltk.FL_NO_BOX)
  end
end
w:show()
Fl:run()
