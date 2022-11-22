--
-- Menu example
--

--[[
function menu_callback(w)
   print (w:value() .. " - " .. w:text());

   if w:mvalue():user_data() then
      print ("User Data is " .. w:mvalue():user_data())
   end

   -- w:mvalue():deactivate()
   io.flush();
end
]]

function item1_callback()
	fltk.fl_message ("Called the item 1 callback")
   io.flush();
end
function item2_callback()
	fltk.fl_message ("Called the item 2 callback")
   io.flush();
end

local window = fltk:Fl_Double_Window(394, 150);
local menuBar = fltk:Fl_Menu_Bar(0, 0, 395, 25);

menuBar:add("&First menu item/First item", fltk.FL_CTRL + string.byte("f"));
menuBar:add("First menu item/Second test", fltk.FL_ALT + string.byte("s"), item1_callback);
menuBar:add("First menu item/Third test", nil, nil, "Some user data", fltk.FL_MENU_TOGGLE);

menuBar:add("Second menu item/&First item", nil, item1_callback);
menuBar:add("Second menu item/&Second test");
index = menuBar:add("Second menu item/&Third test");
menuBar:menu(index):callback(item2_callback)

-- WARNING, if you use a menu-wide callback you MUST set after all items have been created
--menuBar:callback(menu_callback);

menuBar:global()

window:show();
Fl:run();
