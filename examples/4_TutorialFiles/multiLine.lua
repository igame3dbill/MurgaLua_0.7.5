function refresh_callback(w)
  outputField:value(inputField:value())
end

do local object = fltk:Fl_Double_Window(484, 130, "Multiline Example");
    window = object;

    inputField = fltk:Fl_Multiline_Input(5, 5, 200, 120);
    inputField:wrap(1)

    outputField = fltk:Fl_Multiline_Output(275, 5, 200, 120);
    outputField:wrap(1)

    refreshButton = fltk:Fl_Button(210, 5, 60, 50, "Refresh >>>>>");
    refreshButton:align(fltk.FL_ALIGN_WRAP);
    refreshButton:callback(refresh_callback)
end
window:show();
Fl:run();
