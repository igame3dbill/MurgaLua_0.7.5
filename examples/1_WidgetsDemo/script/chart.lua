w=fltk:Fl_Double_Window(600,400,"chart.lua")
-- chart widget

math.randomseed(os.time()) -- set random seed for math.random()

function change_bar_type(self)
-- grab the number from the beginning of the active button's
-- label string and use it to set the chart type
my_chart:type(string.sub(self:label(),1,1))
my_chart:redraw()
end

my_chart=fltk:Fl_Chart(10,20,300,300,"fltk:Fl_Chart\(x,y,w,h,label\)")
my_chart:bounds(0,100)
for i=1,5 do -- create 5 chart items
-- each item is created from a random number between 0-100
-- the color of each is inherited from its item number
my_chart:add(math.random(0,100),"item "..i,i)
end

-- I couldnt figure out how to use button labels as constants to set the
-- chart type, so these are included only as a visual part of the label
chart_buttons={}
chart_types={"FL_BAR_CHART","FL_HORBAR_CHART","FL_LINE_CHART","FL_FILLED_CHART","FL_SPIKE_CHART","FL_PIE_CHART","FL_SPECIALPIE_CHART"}

for i=0,6 do
-- create a radio button for each chart type
chart_buttons[i]=fltk:Fl_Round_Button(320,i*30+20,200,30,i.." "..chart_types[i+1])
chart_buttons[i]:type(fltk.FL_RADIO_BUTTON)
chart_buttons[i]:callback(change_bar_type)
end
chart_buttons[0]:value(1)

Fl:focus(chart_buttons[0])
w:show()
Fl:run()
