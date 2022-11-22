w=fltk:Fl_Double_Window(500,400,"browser.lua")

function browser_add_line()
  if br_one_input:value()~="" then
    br_one:add(br_one_input:value())
    br_two:add(br_one_input:value())
    br_three:add(br_one_input:value())
    br_four:add(br_one_input:value())
    br_four:redraw() -- check browser apparently doesn't refresh itself
    br_one_input:value("")
  end
end

function browser_rev_line(br)
  if br:value() > 0 then
    browser_new_line=string.reverse(br:text(br:value()))
    br:text(br:value(),browser_new_line)
  end
end

function browser_move_down()
if br_two:value() > 0 then
local target=br_two:value()+1
br_two:move(br_two:value(),target)
end
end

function browser_move_up()
if br_two:value() > 0 and br_two:value() <= br_two:size() then
local target=br_two:value()-1
br_two:move(br_two:value(),target)
end
end

br_one=fltk:Fl_Select_Browser(10,10,200,120,"Fl_Select_Browser\n(select reverses text)"); br_one:callback(browser_rev_line)
br_one_input=fltk:Fl_Input(220,10,230,25)
br_one_add=fltk:Fl_Return_Button(220,35,230,25,"add a line"); br_one_add:callback(browser_add_line)

br_two=fltk:Fl_Hold_Browser(10,180,200,120,"Fl_Hold_Browser")
br_two_move_up=fltk:Fl_Button(210,180,25,25,"@8>") -- see "Labels and Label Types" in the FLTK documentation
br_two_move_up:tooltip("move selection up")
br_two_move_up:callback(browser_move_up)
br_two_move_dn=fltk:Fl_Button(210,205,25,25,"@2>")
br_two_move_dn:tooltip("move selection down")
br_two_move_dn:callback(browser_move_down)
br_two_del=fltk:Fl_Button(210,230,25,25,"@7+")
br_two_del:tooltip("delete selection")
br_two_del:callback(function(br_two_del_cb) if br_two:value() > 0 then br_two:remove(br_two:value()) end end)

br_three=fltk:Fl_Multi_Browser(250,80,200,100,"Fl_Multi_Browser")
br_four=fltk:Fl_Check_Browser(250,200,200,100,"Fl_Check_Browser")

Fl:focus(br_one_input) -- giving it focus makes it a little more convenient
w:show()
Fl:run()
