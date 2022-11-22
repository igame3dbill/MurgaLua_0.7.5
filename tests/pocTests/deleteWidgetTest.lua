local object = fltk:Fl_Double_Window(200, 100);

window = object;

button1 = fltk:Fl_Button(25, 25, 150, 25, "Remove Button");
button2 = fltk:Fl_Button(25, 60, 150, 25, "Will go");

function remove_callback(data)
  window:remove(button2)
  Fl:delete_widget(button2)
  window:redraw()
  button2=nil
end

button1:callback(remove_callback)

window:show();
Fl:run();
