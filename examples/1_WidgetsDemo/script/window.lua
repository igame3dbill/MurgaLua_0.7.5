w=fltk:Fl_Double_Window(260,80,"window.lua")

show_butt=fltk:Fl_Button(10,10,120,30,"show")
show_butt:callback(function()
  my_win:border(borderbutt:value())
  -- disable the modal toggle after this, since it is no longer useable
  if modalbutt:value()==1 then my_win:set_modal(); modalbutt:set_output() end
  my_win:show()
end )
hide_butt=fltk:Fl_Button(130,10,120,30,"hide")
hide_butt:callback(function() my_win:hide() end )
borderbutt=fltk:Fl_Toggle_Button(10,40,120,30,"with border")
borderbutt:value(1)
modalbutt=fltk:Fl_Toggle_Button(130,40,120,30,"modal")

-- everything after this will be on the second window
-- I assumed I would need Fl_End(), but it crashes, apparently due to nesting
my_win=fltk:Fl_Double_Window(300,200,"my new window")
-- the upper an lower limits to manual resizing
-- the first (commented) example includes resize increments and fixed-ratio toggle
-- the 0 indicates no fixed ratio (lower and upper ratios must be the same for 1 to work)
--my_win:size_range(100,50,500,350,50,50,0)
my_win:size_range(300,200,Fl:w()/1.5,Fl:h()/1.5)

-- tiled background image
my_background=fltk:Fl_Box(0,0,Fl:w(),Fl:h()) -- uses screen size
my_tile_image=fltk:Fl_JPEG_Image(images.."tile.jpg")
my_tile=fltk:Fl_Tiled_Image(my_tile_image,Fl:w(),Fl:h())
my_background:image(my_tile)

my_box=fltk:Fl_Box(140,10,150,180,"Most Fl_Window() methods are limited by what your desktop environment allows.")
my_box:box(fltk.FL_THIN_DOWN_BOX)
my_box:align(220) -- wrap, inside left, clip
--my_win:resizable(my_box)

min_butt=fltk:Fl_Button(10,10,120,30,"iconize")
min_butt:callback(function() my_win:iconize() end )

res_butt=fltk:Fl_Button(10,40,120,30,"resize")
res_butt:callback(function() my_win:resize(100,100,300,200) end )

-- supposedly unfreezes the resize
free_butt=fltk:Fl_Button(10,70,120,30,"free position")
free_butt:callback(function() my_win:free_position() end )

-- toggle fullscreen
fs_butt=fltk:Fl_Toggle_Button(10,100,120,30,"fullscreen")
fs_butt:callback( function(self)
if self:value()==0 then
my_win:fullscreen_off(my_win_x,my_win_y,my_win_w,my_win_h)
-- hotspot doesn't work as I'd hoped =op
--my_win:hotspot(fs_butt,1)
else
-- get current size and position, for use with fullscreen_off()
my_win_x=my_win:x()
my_win_y=my_win:y()
my_win_w=my_win:w()
my_win_h=my_win:h()
my_win:fullscreen()
end
end )

-- nudge window 10 pixels
left_butt=fltk:Fl_Repeat_Button(10,130,30,30,"@<-")
left_butt:callback( function() my_win:position(my_win:x()-10,my_win:y()) end )
left_butt:tooltip("nudge left")
up_butt=fltk:Fl_Repeat_Button(40,130,30,30,"@2<-")
up_butt:callback( function()  my_win:position(my_win:x(),my_win:y()-10) end )
up_butt:tooltip("nudge up")
dn_butt=fltk:Fl_Repeat_Button(70,130,30,30,"@8<-")
dn_butt:callback( function() my_win:position(my_win:x(),my_win:y()+10) end )
dn_butt:tooltip("nudge down")
right_butt=fltk:Fl_Repeat_Button(100,130,30,30,"@->")
right_butt:callback( function() my_win:position(my_win:x()+10,my_win:y()) end )
right_butt:tooltip("nudge right")

out_butt=fltk:Fl_Repeat_Button(10,160,30,30,"@->|")
out_butt:callback( function() my_win:size(my_win:w()+10,my_win:h()) end )
out_butt:tooltip("wider")
in_butt=fltk:Fl_Repeat_Button(40,160,30,30,"@$->|")
in_butt:callback( function() if my_win:w()>300 then my_win:size(my_win:w()-10,my_win:h()) end end )
in_butt:tooltip("narrower")
tall_butt=fltk:Fl_Repeat_Button(70,160,30,30,"@2->|")
tall_butt:callback( function() my_win:size(my_win:w(),my_win:h()+10) end )
tall_butt:tooltip("taller")
short_butt=fltk:Fl_Repeat_Button(100,160,30,30,"@8->|")
short_butt:callback( function() if my_win:h()>200 then my_win:size(my_win:w(),my_win:h()-10) end end )
short_butt:tooltip("shorter")
w:show()
Fl:run()
