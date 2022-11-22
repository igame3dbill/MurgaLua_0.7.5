w=fltk:Fl_Double_Window(440,360,"wizard.lua")

function wizz_pick(self)
-- choose a specific pane
-- uses the button label to pick the wizz_pages index
wizz:value(wizz_pages[tonumber(string.sub(self:label(),2,2))])
end

wizz=fltk:Fl_Wizard(20,20,400,280,"fltk:Fl_Wizard\(x,y,w,h,label\)")
fltk:Fl_End() -- if this is not used, everything after will be placed on the wizard's first page
wizz:color2(fltk.FL_RED)

-- navigation buttons
-- they must be positioned outside the wizard boundaries
wizz_prev_butt=fltk:Fl_Button(20,300,100,30,"@<-  &prev()")
wizz_prev_butt:callback(function(wizz_prev) wizz:prev() end)
wizz_next_butt=fltk:Fl_Button(320,300,100,30,"&next()  @->")
wizz_next_butt:callback(function(wizz_next) wizz:next() end)
wizz0=fltk:Fl_Button(120,300,50,30,"&0"); wizz0:callback(wizz_pick)
wizz1=fltk:Fl_Button(170,300,50,30,"&1"); wizz1:callback(wizz_pick)
wizz2=fltk:Fl_Button(220,300,50,30,"&2"); wizz2:callback(wizz_pick)
wizz3=fltk:Fl_Button(270,300,50,30,"&3"); wizz3:callback(wizz_pick)

wizz_pages={}
wizz_text={}

-- this first pane has a layout unique from the others
wizz_pages[0]=fltk:Fl_Group(20,20,400,280)
wizz_splash=fltk:Fl_Box(20,20,220,200)
wizz_splash:image(fltk:Fl_XBM_Image(images.."xbm_image.xbm"))
wizz_splash_text=fltk:Fl_Box(240,20,180,200,"This is a demo of the FLTK wizard widget. "..
"It presents a series of pages in sequence.\n\n"..
"It works much like the tabs widget, but is controlled by programming rather than by clicking tabs.")
wizz_splash_text:labelsize(12)
wizz_splash_text:align(fltk.FL_ALIGN_WRAP)
fltk:Fl_End()
wizz:add(wizz_pages[0])

-- automated creation of the remaining wizard panes
for i=1,3 do
wizz_pages[i]=fltk:Fl_Group(20,20,400,280)
wizz_text[i]=fltk:Fl_Box(20,20,400,280) -- simple box for text
wizz_text[i]:align(fltk.FL_ALIGN_WRAP)
fltk:Fl_End()
wizz:add(wizz_pages[i])
wizz_text[i]:labelsize(12)
end

-- set the text for the automated panes
wizz_text[1]:label("As with Fl_Tabs, wizard panes are composed of child (usually Fl_Group) widgets. Navigation buttons must be added separately.")
wizz_text[2]:label("step 2")
wizz_text[3]:label("step 3")

w:show()
Fl:run()
