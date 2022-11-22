w = fltk:Fl_Double_Window(900,300);
widths = { 50, 50, 50, 70, 70, 40, 40, 70, 70, 50, 0 };
b = fltk:Fl_Multi_Browser(10,10,w:w()-20,w:h()-20);
b:column_widths(widths);
murgaLua.printDebug(b:column_widths(),4)
b:column_char(string.byte('|'));

-- NICER COLORED HEADING
b:add("@B12@C7@b@.USER|@B12@C7@b@.PID|@B12@C7@b@.%CPU|" ..
      "@B12@C7@b@.%MEM|@B12@C7@b@.VSZ|@B12@C7@b@.RSS|" .. 
      "@B12@C7@b@.TTY|@B12@C7@b@.STAT|@B12@C7@b@.START|" ..
      "@B12@C7@b@.TIME|@B12@C7@b@.COMMAND");

-- COLUMNS OF DATA
b:add("root|2888|0.0|0.0|1352|0|tty3|SW|Aug15|0:00|@b@f/sbin/mingetty tty3");
b:add("erco|2889|0.0|13.0|221352|0|tty3|R|Aug15|1:34|@b@f/usr/local/bin/render a35 0004");
b:add("uucp|2892|0.0|0.0|1352|0|ttyS0|SW|Aug15|0:00|@b@f/sbin/agetty -h 19200 ttyS0 vt100");
b:add("root|13115|0.0|0.0|1352|0|tty2|SW|Aug30|0:00|@b@f/sbin/mingetty tty2");
b:add("root|13464|0.0|0.0|1352|0|tty1|SW|Aug30|0:00|@b@f/sbin/mingetty tty1 --noclear");
w:resizable(b);
--w:end();
w:show();
Fl:run()
