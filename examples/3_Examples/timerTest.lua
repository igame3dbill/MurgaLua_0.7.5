local object = fltk:Fl_Double_Window(200, 100);

window = object;
counter = 0;

timer = murgaLua.createFltkTimer()

button1 = fltk:Fl_Button(25, 25, 150, 25, "Start the timer");
button2 = fltk:Fl_Button(25, 60, 150, 25, "Stop the timer");

function start_callback(data)
  counter =0;
  timer:doWait(0.01)
end

function stop_callback(data)
  if (timer:isActive() == 1) then
    timer:doWait(0)
  else
    timer:doWait(0.01)
  end
end

function sleep_callback(data)
  counter = counter + 1
  button2:label(counter)
  timer:doWait(0.01)
end
    
button1:callback(start_callback)
button2:callback(stop_callback)
timer:callback(sleep_callback)

window:show();
Fl:run();
