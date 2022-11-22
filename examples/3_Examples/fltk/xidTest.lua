window = fltk:Fl_Window(310, 115, "XID Tests");

call_fl_xid  = fltk:Fl_Button(5, 5, 300, 50, "fl_xid");
call_fl_find = fltk:Fl_Button(5, 60, 300, 50, "fl_find");

call_fl_xid:callback(
	function(w)
		call_fl_xid:label("XID of window is : " .. fltk.fl_xid(window))
	end)

call_fl_find:callback(
	function(w)
		fltk.fl_find(fltk.fl_xid(window)):label("Changed !!")
		call_fl_find:label("Changed window title using XID")
	end)

window:show()

Fl:run()
