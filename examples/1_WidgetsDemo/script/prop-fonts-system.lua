-- system fonts

-- I have no idea what the name of the font table is so I'm making my own
-- This is redundant, but it works
my_fonts={}

-- set_fonts() adds all fonts to the font table
-- and returns the total number of fonts
numfonts=Fl:set_fonts()

-- callback for all the font buttons
function set_my_font(self)
  for i=0,numfonts do
    if self == my_fonts[i] then -- if the pressed button is the same as the button created for my_fonts[i]
      fonttextdisplay:labelfont(i) -- change the font of the displayed text
      fonttextdisplay:redraw_label() -- the change isn't visible until a redraw is done
      break
    end
  end
end

function set_my_fontsize()
  fonttextdisplay:labelsize(sysfonts_slider:value()) -- change the font size of the displayed text
  fonttextdisplay:redraw_label()
end

w=fltk:Fl_Double_Window(540,400,"fonts-system.lua")
-- make a container for lots of buttons
font_scroll = fltk:Fl_Scroll(0,0,260,300)
fltk:Fl_End()
-- pack the buttons below into an expandable area
font_pack = fltk:Fl_Pack(0,0,240,300)
fltk:Fl_End()
font_scroll:add(font_pack)

-- create a button for each font
for i=0,numfonts do
  my_font=Fl:get_font(i) -- get the name of the current font
  if my_font then
    table.insert(my_fonts,i)
    --** my_fonts[i]=fltk:Fl_Light_Button(0,i*30,240,30,my_font)
    my_fonts[i]=fltk:Fl_Light_Button(0,0,240,30,my_font)
    my_fonts[i]:type(fltk.FL_RADIO_BUTTON)
    my_fonts[i]:callback(set_my_font)
    my_fonts[i]:align(20) -- label is aligned inside and left
    --** font_scroll:add(my_fonts[i]) -- add the button to font_scroll
    font_pack:add(my_fonts[i]) -- add the button to font_pack
  end
end

fonttextdisplay=fltk:Fl_Button(270,0,270,300,
[[jackdaws love my big sphinx of quartz

PACK MY BOX WITH FIVE DOZEN LIQUOR JUGS

"1234567890@@
`~!#$%^&*()_+-=
{}[]\|;:'\"<>,./?]])
fonttextdisplay:align(192)

sysfonts_slider=fltk:Fl_Value_Slider(0,300,420,30,"font size")
sysfonts_slider:align(fltk.FL_ALIGN_RIGHT)
sysfonts_slider:minimum(2)
sysfonts_slider:maximum(48)
sysfonts_slider:step(1) -- makes the slider show only integers
sysfonts_slider:type(fltk.FL_HOR_NICE_SLIDER)
sysfonts_slider:value(fonttextdisplay:labelsize()) -- this just prevents a jumpy change when the slider is first moved
sysfonts_slider:callback(set_my_fontsize)
w:show()
Fl:run()
