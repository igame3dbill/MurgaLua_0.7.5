#!/usr/bin/murgaLua

--
-- Menu example
--

added = nil;

function menu_callback(w)
   print ("Called the GLOBAL callback")
   print (w:mvalue():serial() .. " - " .. w:text());

   if w:mvalue():user_data() then
      print ("User Data is '" .. w:mvalue():user_data() .. "'")
   end

   io.flush();
end

function item1_callback(w)
	print ("Called the item 1 callback")
	if w:user_data() then
		print ("User Data is '" .. w:user_data() .. "'")
    end
    io.flush();
end
function item2_callback(w)
	print ("Called the item 2 callback")
	print(w:serial() .. " - " .. w:label())
	if w:user_data() then
		print ("User Data is '" .. w:user_data() .. "'")
    end
    io.flush();

	if not added then
		w:getMenu():add("New Menu/My new item")
		w:getMenu():redraw()
		added = 1
	end
end

local window = fltk:Fl_Double_Window(394, 150);
local menuBar = fltk:Fl_Menu_Bar(0, 0, 395, 25);

menuBar:add("&First menu item/First item", fltk.FL_CTRL + string.byte("f"));
menuBar:add("First menu item/Second test", fltk.FL_ALT + string.byte("s"), item2_callback, "More user Data");
menuBar:add("First menu item/Third test", nil, nil, "Some user data", fltk.FL_MENU_TOGGLE);

menuBar:add("Second menu item/&First item", nil, item1_callback);
menuBar:add("Second menu item/&Second test", nil, nil, "Test user data");
menuBar:add("Second menu item/&Third test", nil, item2_callback);

index = menuBar:add("Second menu item/&Forth test");
menuBar:menu(index):callback(item2_callback)

menuBar:replace(1 , "New first item")

print ("For window accessed through menuBar:window().")
print ("UserData test : serial = " .. menuBar:window():serial() .. " UserData pointer = " .. tostring(menuBar:window()))
print ("And for same window accessed directly :")
print ("UserData test : serial = " .. window:serial() .. " UserData pointer = " .. tostring(window))
print ()
io.flush();
	
-- WARNING, if you use a menu-wide callback you MUST set after all items have been created
menuBar:callback(menu_callback);

menuBar:global()

window:show();
Fl:run();
