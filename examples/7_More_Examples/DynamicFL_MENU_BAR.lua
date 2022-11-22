--[[Dynamic menus by Mikshaw
You can use Fl_Menu_Bar:find_item(my_menu_item_string) 
to get a pointer to a specific menu item, which is much more pleasant 
than trying to determine the index of a particular menu item.
this seems to work with menu items created with my_menu:add(my_menu_item_string).
]]--

my_menu=fltk:Fl_Menu_Bar(0,0,window_width,30)
my_menu:add("&File/open")
my_menu:add("&File/save")
save_item=my_menu:find_item("&File/save")

--Now you can disable the "save" item when it's not needed:

save_item:deactivate()
--[[This can also be used to perform (most?) other actions that
 can be applied to the Fl_Menu_ class, such as replacing/renaming items. 
The only things i've tested so far is changing font properties and item labels.]]--