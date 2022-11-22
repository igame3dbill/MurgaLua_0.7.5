mode = nil

file_small = {
"16 16 7 1",
" 	c None",
".	c #000000000000",
"X	c #CF3CCF3CFFFF",
"o	c #AEBADB6CE79D",
"O	c #659565959A69",
"+	c #9A699A69CF3C",
"@	c #DF7DDF7DDF7D",
"                ",
"                ",
"                ",
"      .         ",
"     .X..       ",
"    .XXXX..     ",
"   .Xoooooo..   ",
"  .Xooooooooo.. ",
" .XoooooooooooX.",
".XXXXXXXXXXXXX.O",
" .XXXXXXXXXXX.+O",
"  ..XXXXXX@X.+.O",
"   ...+++++..O  ",
"    .+..OO.O    ",
"     .X+..O     ",
"      .. O      "}

folder_small = {
"16 16 23 1",
" 	c None",
".	c #000000000000",
"X	c #FFFFFFFFFFFF",
"o	c #CF3CCF3CCF3C",
"O	c #FFFF9A699A69",
"+	c #EFBEEFBEEFBE",
"@	c #FFFFFFFF9A69",
"#	c #FFFFFFFFCF3C",
"$	c #CF3CCF3C30C2",
"%	c #CF3C9A6930C2",
"&	c #9A699A696595",
"*	c #FFFFCF3CCF3C",
"=	c #FFFFFFFF30C2",
"-	c #DF7DDF7DDF7D",
";	c #FFFFCF3C6595",
":	c #9A6965956595",
">	c #FFFFCF3C30C2",
",	c #FFFFFFFF6595",
"<	c #FFFFFFFF0000",
"1	c #9A699A699A69",
"2	c #75D675D675D6",
"3	c #208120812081",
"4	c #659565956595",
"   .. ..        ",
"   .X..o..      ",
".. .XXX..O..... ",
".+..@#XXX..$%%. ",
".+++..@##XX..&O.",
" .*=**..-@#XX.%.",
" .*;**+;..:@#.& ",
" .*;>o*;;o..@.& ",
"  .**+*o*o*.@.. ",
"  .**;*o**o.,.  ",
"   .;>;;;;;.<.  ",
"   .;;;;;;;%..1 ",
"    ..;;;>;;..22",
"      ..;;;>.32 ",
"        ..;;.4  ",
"          ...   "}

close_icon = {
"16 16 4 1 0 0",
"  c #000000",
"! c #7592FF",
"# c #FFFFFF",
"$ c None",
"$$$$$$$$$$$$$$$$",
"$$$$$$$$$$$$$$$$",
"$$$$$$$$$$$$$$$$",
"$$$$$$ $$$$$$$$$",
"$$$$$$  $$$$$$$$",
"$$$$$$ ! $$$$$$$",
"$$$$$$ !! $$$$$$",
"$$$$$$ !!! $$$$$",
"$$$$$$ !!!! $$$$",
"$$$$$$ !!! $$$$$",
"$$$$$$ !! $$$$$$",
"$$$$$$ ! $$$$$$$",
"$$$$$$  $$$$$$$$",
"$$$$$$ $$$$$$$$$",
"$$$$$$$$$$$$$$$$",
"$$$$$$$$$$$$$$$$"}

open_icon = {
"16 16 4 1 0 0",
"  c #000000",
"! c #7592FF",
"# c #FFFFFF",
"$ c None",
"$$$$$$$$$$$$$$$$",
"$$$$$$$$$$$$$$$$",
"$$$$$$$$$$$$$$$$",
"$$$$$$$$$$$$$$$$",
"$$$$$$$$$$$$$$$$",
"$$$           $$",
"$$$$ !!!!!!! $$$",
"$$$$$ !!!!! $$$$",
"$$$$$$ !!! $$$$$",
"$$$$$$$ ! $$$$$$",
"$$$$$$$$ $$$$$$$",
"$$$$$$$$$$$$$$$$",
"$$$$$$$$$$$$$$$$",
"$$$$$$$$$$$$$$$$",
"$$$$$$$$$$$$$$$$",
"$$$$$$$$$$$$$$$$"}

function cb_draw_lines()
  if (tree:draw_lines() == 0) then tree:draw_lines(1) else tree:draw_lines(0) end
  tree:redraw()
end

function cb_mac_colors()
  if (tree:alternate_color() == tree:color()) then
      tree:alternate_color(fltk.FL_LIGHT2)
      tree:trim_color(fltk.FL_LIGHT1)
  else
      tree:alternate_color(tree:color())
      tree:trim_color(tree:color())
  end
  tree:redraw()
end

function cb_add_folder()
  sel = tree:selected()
  if (not sel) then
    tree:add_next("New Folder", 1, folderSmall)
    return
  end

  tree:traverse_start(sel)
  if (sel:is_open() and sel:can_open()) then
    tree:add_sub("New Folder", 1, folderSmall)
  else
    tree:add_next("New Folder", 1, folderSmall)
  end
end

function cb_add_paper()
  sel = tree:selected()
  if (not sel) then
    tree:add_next("New Sheet", 0, fileSmall)
    return
  end

  tree:traverse_start(sel)
  if (sel:is_open() and sel:can_open()) then
    tree:add_sub("New Sheet", 0, fileSmall)
  else
    tree:add_next("New Sheet", 0, fileSmall)
  end
end

function cb_test(tree)

  print("state: " .. tree:state())

  if (tree:selected()) then
    print("current=" .. tree:selected():label())
  else
    print("MULTIPLE")
    s = tree:selection()
    while(s) do
	  print(s:label())
	  s = tree:selection()
	end

    n = tree:selection_count()
    print("Selections: " .. n)
	
    for i = 0,(n-1) do
      s = tree:selection(i)
      print(i .. " - " .. s:label())
    end
  end
  io.flush()
end

function cb_remove()
  if (tree:selected()) then
    tree:remove(tree:selected())
  else
    s = tree:selection()
    while(s) do
      tree:remove(s)
	  s = tree:selection()
	end
  end
  tree:redraw()
end

function cb_no_edit_row()
  if (tree:selected()) then
    tree:selected():can_edit(1)
  else
    s = tree:selection()
    while(s) do
	  s:can_edit(1)
	  s = tree:selection()
	end
  end
end

function cb_no_icons()
	while tree:first() do tree:clear() end -- BUG with underlying binding
	if (mode) then
		tree:draw_lines(0)
		folderSmall = fltk:Fl_Pixmap()
		fileSmall = fltk:Fl_Pixmap()
		tree:opened_pixmap(fltk:Fl_Pixmap(open_icon))
		tree:closed_pixmap(fltk:Fl_Pixmap(close_icon))
		tree:label_offset(20)
		mode = false
	else
		tree:draw_lines(1)
		tree:opened_pixmap(defaultOpen)
		tree:closed_pixmap(defaultClose)
		folderSmall = fltk:Fl_Pixmap(folder_small)
		fileSmall = fltk:Fl_Pixmap(file_small)
		tree:label_offset(40)
		mode = true
	end
	populateTree()
	tree:update_height()
	tree:redraw()
	scroll:redraw()
end

function cb_no_edit_table()
	tree:edit_on_reselect(0)
end

function populateTree()
  tree:add_next("aaa\t123", 1, folderSmall)

  tree:add_sub("bbb TWO\t456", 1, folderSmall)
  tree:traverse_up()

  node = tree:add_next("bbb", 1, folderSmall)
  tree:close(node)

  tree:add_sub("ccc\t789", 1, folderSmall)
  tree:add_sub("ddd\t012", 0, fileSmall)
  tree:traverse_up()
  tree:traverse_up()

  tree:add_next("eee", 1, folderSmall)
  tree:add_sub("fff", 0, fileSmall)
  tree:traverse_up()

  tree:add_next("ggg", 1, folderSmall)
  node = tree:add_sub("hhh", 1, fileSmall)
  tree:close(node)
  tree:add_sub("iii", 1, fileSmall)
  tree:traverse_up()
  tree:traverse_up()

  tree:add_next("jjj", 1, folderSmall)
  tree:add_sub("kkk", 0, fileSmall)
  tree:traverse_up()

  tree:add_next("lll", 0, fileSmall)
  node = tree:add_next("mmm", 1, folderSmall)
  tree:close(node)
  tree:add_sub("nnn", 1, folderSmall)
  tree:add_sub("ooo", 0, fileSmall)
  tree:traverse_up()
  tree:traverse_up()

  tree:add_next("ppp", 1, folderSmall)
  tree:add_sub("qqq", 0, fileSmall)
  tree:traverse_up()

  tree:add_next("rrr", 1, folderSmall)
  tree:add_sub("sss", 1, folderSmall)
  tree:add_sub("ttt", 1, folderSmall)
  tree:traverse_up()
  tree:traverse_up()

  tree:add_next("uuu", 1, folderSmall)
  tree:add_sub("vvv", 0, fileSmall)
  tree:traverse_up()

  tree:add_next("www", 0, fileSmall)
  tree:add_next("xxx", 0, fileSmall)
  tree:add_next("yyy", 0, fileSmall)
  tree:add_sub("zzz", 0, fileSmall)
end

win = fltk:Fl_Window(240, 304, "Tree Example")
remove_button = fltk:Fl_Button(10, 200, 100, 22, "Remove")
add_paper_button = fltk:Fl_Button(10, 224, 100, 22, "Add Sheet")
add_folder_button = fltk:Fl_Button(10, 248, 100, 22, "Add Folder")
draw_lines_button = fltk:Fl_Button(130, 200, 100, 22, "Lines on/off")
mac_colors_button = fltk:Fl_Button(130, 224, 100, 22, "Colors scheme")
no_edit_row_button = fltk:Fl_Button(130, 248, 100, 22, "Row editable")
no_icons_button = fltk:Fl_Button(10, 272, 100, 22, "Reset/No Icons");
no_edit_table_button = fltk:Fl_Button(130, 272, 100, 22, "Tree/No Edit");
  
scroll = fltk:Fl_Scroll(10, 10, 220, 180)
scroll:type(Fl_Scroll.VERTICAL_ALWAYS)
scroll:box(fltk.FL_THIN_DOWN_FRAME)
tree = fltk:Fl_ToggleTree(12, 12, 200, 10)
defaultOpen  = tree:opened_pixmap()
defaultClose = tree:closed_pixmap()

w = {150, 200, 0}
tree:column_widths(w)
scroll:endd()

remove_button:callback(cb_remove)
tree:callback(cb_test)

no_icons_button:callback(cb_no_icons)
no_edit_row_button:callback(cb_no_edit_row)
no_edit_table_button:callback(cb_no_edit_table)

add_paper_button:callback(cb_add_paper)
add_folder_button:callback(cb_add_folder)
draw_lines_button:callback(cb_draw_lines)
mac_colors_button:callback(cb_mac_colors)

cb_no_icons() -- Re-using the population code

-- Last minute deletion tests

if (tree:remove("xxx") ~= 0) then
	print("Successfully deleted \"xxx\"\n")
else
	print("Could not delete \"xxx\"\n")
end

if (tree:remove("nonexistant") ~= 0) then
	print("Successfully deleted \"nonexistant\"\n")
else
	print("Could not delete \"nonexistant\"\n")
end

win:show()
Fl:run()
