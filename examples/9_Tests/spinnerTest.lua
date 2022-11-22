  do local object = fltk:Fl_Double_Window(115, 100);
    window = object;
    fltk:Fl_Spinner(20, 20, 80, 45);
  end
  window:show();
  Fl:run();
