function print_info(event)
		if (event ~= 0) then
			myField:value( murgaLua.getFltkEventText(event) .. " - " .. Fl:event_text())
		else
			myField:value( Fl:event_x() .. " - " .. Fl:event_y())
		end
	end

  do local object = fltk:Fl_Double_Window(166, 165, "My App");
    window = object;
    myButton = fltk:Fl_Return_Button(5, 130, 155, 30, "A return button");
    myOptions = fltk:Fl_Check_Browser(5, 5, 155, 70, "Some choices");
    myField = fltk:Fl_Input(5, 95, 155, 30);

    myOptions:add("Shower and shave") 
    myOptions:add("Breakfast") 
    myOptions:add("Watch TV") 
    myOptions:add("Go to work") 
    myOptions:add("Call the plumber")
    
    myField:callback(
      function(myField)
          fltk.fl_message("Changed the value to \"" .. myField:value() .. "\"")
    end)
	
	myButton:callback(
      function(myField)
          Fl:stop_event_handler()
    end)

	Fl.set_event_handler( print_info )
    window:callback( print_info )
	
	Fl:start_event_handler()
	
	-- set_event_handler
	-- start_event_handler
	-- stop_event_handler
  end
  window:show();
  Fl:run();
