-- built-in fonts

function fontbutt_set_label(self)
  fonttextdisplay:labelfont(self:labelfont())
  fonttextdisplay:redraw()
end

function set_my_fontsize()
  fonttextdisplay:labelsize(fonts_slider:value()) -- change the font size of the displayed text
  fonttextdisplay:redraw_label()
end

fontbutts={} -- create a new table for the buttons
fontlabels={} -- same for labels

fontlabels[0]="fltk.FL_HELVETICA"
fontlabels[1]="fltk.FL_HELVETICA_BOLD"
fontlabels[2]="fltk.FL_HELVETICA_ITALIC"
fontlabels[3]="fltk.FL_HELVETICA_BOLD_ITALIC"
fontlabels[4]="fltk.FL_COURIER"
fontlabels[5]="fltk.FL_COURIER_BOLD"
fontlabels[6]="fltk.FL_COURIER_ITALIC"
fontlabels[7]="fltk.FL_COURIER_BOLD_ITALIC"
fontlabels[8]="fltk.FL_TIMES"
fontlabels[9]="fltk.FL_TIMES_BOLD"
fontlabels[10]="fltk.FL_TIMES_ITALIC"
fontlabels[11]="fltk.FL_TIMES_BOLD_ITALIC"
fontlabels[12]="fltk.FL_SYMBOL"
fontlabels[13]="fltk.FL_SCREEN"
fontlabels[14]="fltk.FL_SCREEN_BOLD"
fontlabels[15]="fltk.FL_ZAPF_DINGBATS"

w=fltk:Fl_Double_Window(540,400,"fonts-builtin.lua")
-- creating a table for similar data enables easy automation using 'for' loops
for i=0,15 do
fontbutts[i]=fltk:Fl_Light_Button(0,20*i,300,20)
fontbutts[i]:labelfont(i)
fontbutts[i]:type(fltk.FL_RADIO_BUTTON)
fontbutts[i]:label(fontlabels[i].." ("..i..")")
fontbutts[i]:callback(fontbutt_set_label)
end

fonttextdisplay=fltk:Fl_Button(300,0,240,320,
[[jackdaws love my big sphinx of quartz

PACK MY BOX WITH FIVE DOZEN LIQUOR JUGS

"1234567890@@
`~!#$%^&*()_+-=
{}[]\|;:'\"<>,./?]])
fonttextdisplay:align(192) -- 192 is FL_WRAP + FL_CLIP

fonts_slider=fltk:Fl_Value_Slider(0,320,420,30,"font size")
fonts_slider:align(fltk.FL_ALIGN_RIGHT)
fonts_slider:minimum(2)
fonts_slider:maximum(48)
fonts_slider:step(1) -- makes the slider show only integers
fonts_slider:type(fltk.FL_HOR_NICE_SLIDER)
fonts_slider:value(fonttextdisplay:labelsize()) -- this just prevents a jumpy change when the slider is first moved
fonts_slider:callback(set_my_fontsize)
w:show()
Fl:run()
