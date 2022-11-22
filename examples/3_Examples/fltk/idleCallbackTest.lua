window = fltk:Fl_Window(310, 115, "Add idle test");

buttonCallbackStatus  = fltk:Fl_Button(5, 5, 300, 50, "Display callback status");
buttonCallback1Remove = fltk:Fl_Button(5, 60, 300, 25, "Remove idle callback 1");
buttonCallback2Remove = fltk:Fl_Button(5, 90, 300, 25, "Remove idle callback 2");

function myIdleCallBack1(w)
	print("Calling idle callback 1")
	io.flush()
	Fl:check()
	murgaLua.sleep(200)
	Fl:check()
end

idle1 = Fl:add_idle(myIdleCallBack1)
idle2 = Fl:add_idle(
  function(w)
  	print("Calling idle callback 2")
	  io.flush()
	  Fl:check()
	  murgaLua.sleep(200)
	  Fl:check()
	end
)

buttonCallbackStatus:callback(function(w)
		fltk.fl_message("Callback status : Callback 1 = " .. Fl:has_idle(idle1) .. " Callback 2 = " .. Fl:has_idle(idle2))
end)

buttonCallback1Remove:callback(	function(w)
		Fl:remove_idle(idle1)
end)

buttonCallback2Remove:callback(	function(w)
		Fl:remove_idle(idle2)
end)

window:show()

Fl:run()
