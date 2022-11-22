-- Slideshow 
-- Based on code by mikshaw (http://damnsmalllinux.org/cgi-bin/forums/ikonboard.cgi)
-- 09 12 2021 updated for lua files system and modified for Windows OS with extra backlashes
-- assumes you've changed the directory to the one where the script resides
-- and the 'images' folder is in the same folder as the script

ww=400 --window width
wh=400 --window height
pw=ww-40 -- photo dims
ph=ww-160
sh=90 -- scroll height
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
--local images = {}
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
dir = "\\images\\"
ipath= cDirectory..dir -- ending slash is vital

images = listFiles(ipath,"table")  
--images = murgaLua.readDirectory(dir) --  deprecated at some point


fltk.fl_register_images()

function scale_touchingBoundingRect(w,h,maxW,maxH)
  if math.max(w,h) == w then
    ratio = (maxW / w) 
  else 
    ratio = (maxH / h) 
  end
  if math.min(h*ratio,maxH) == maxH then
    ratio = (maxH / h) 
  end
  w,h = scale_ratio(w, h, ratio)
  return w,h
end

function scale_ratio(w, h, ratio)
  w,h = math.floor(w * ratio), math.floor(h * ratio)
  return w,h
end

function get_image_data(self)
  for i=1,table.getn(images) do
    if self:tooltip() == ipath..images[i] then -- find the right image
      iw= icon[i]:w()
      ih = icon[i]:h()
      cw,ch=scale_touchingBoundingRect(iw,ih,pw,ph)
      display:image(icon[i]:copy(cw,ch)) --show it bigger!
      display_label:label(images[i].."\n"..icon[i]:w().."x"..icon[i]:h()) -- show height and width
      display:redraw()
      break
    end
  end
end

w=fltk:Fl_Window(ww,wh,"Photo Gallery")
w:color(55)

display=fltk:Fl_Box(15,15,pw+10,ph+10) -- big image
display_label=fltk:Fl_Box(20,20+ph,pw,40)
display_label:label("")
display:box(fltk.FL_BORDER_BOX)
display:color(55)

scroll_box=fltk:Fl_Scroll(15,300,pw+10,sh)
scroll_box:color(57)
scroll=fltk:Fl_Scroll(16,301,pw+8,sh-2)
scroll:type(1)
scroll:color(55)
pack=fltk:Fl_Pack(20,290,pw,sh)
pack:type(1)
pack:spacing(10)
icon={""}; butt={""}
row=1;col=1
-- since the images table contains more than just images (*.lnk gets in too)
-- i'm building the icons from specific items in the table.
for i=1,table.getn(images) do
  if string.find(images[i],".png",-4,plain) or string.find (images[i],".jpg",-4,plain)
  then
    icon[i]=Fl_Shared_Image.get(ipath..images[i])
    butt[i]=fltk:Fl_Button(0,0,80,80)
    butt[i]:align(fltk.FL_ALIGN_CLIP)
    cw,ch=scale_touchingBoundingRect(icon[i]:w(),icon[i]:h(),200,75)
    butt[i]:image(icon[i]:copy(cw,ch))
    butt[i]:tooltip(ipath..images[i])
    butt[i]:callback(get_image_data)
    butt[i]:color(55)
    butt[i]:box(fltk.FL_NO_BOX)
  end
end
w:show()
Fl:run()
