dofile "sqlFunctions.lua"

database = nil

window  = fltk:Fl_Double_Window(574, 298, "SQL Tool (SqLite " .. sqlite3.version() .. ")");
menuBar = fltk:Fl_Menu_Bar(0, 0, 575, 25);

dbList  = fltk:Fl_Hold_Browser(5, 53, 135, 214, "Tables");
dbList:align(fltk.FL_ALIGN_TOP_LEFT);
tableList = {} -- Work around for murgaLua < = 0.5 problem.

sqlEntry = fltk:Fl_Text_Editor(145, 53, 425, 96, "Sql Input");
sqlEntry:textfont(fltk.FL_COURIER)

inputBuffer = fltk:Fl_Text_Buffer(100)
sqlEntry:buffer(inputBuffer)

sqlOutput = fltk:Fl_Text_Display(145, 167, 425, 100, "Sql Output");
sqlOutput:textfont(fltk.FL_COURIER)
window:resizable(sqlOutput)

outputBuffer = fltk:Fl_Text_Buffer(100)
sqlOutput:buffer(outputBuffer)

connectionStatus = fltk:Fl_Box(5, 273, 565, 21, "No open database");
connectionStatus:box(fltk.FL_UP_BOX);
connectionStatus:align(fltk.FL_ALIGN_LEFT+fltk.FL_ALIGN_INSIDE)

maxRows = fltk:Fl_Spinner(504, 28, 65, 24, "Max Rows");
maxRows:minimum(100);
maxRows:maximum(10000);
maxRows:step(100);
maxRows:value(1000);
maxRows:deactivate()

function table_callback(w)
   selectedRow = dbList:value()
   if selectedRow ~=0 then
     inputBuffer:text("select * from " .. tableList[selectedRow])
   end
end

function menu_callback(w)

   if (w:value() == 1) then

      fileName = fltk.fl_file_chooser("Choose database file or enter NEW name to create","*.db",".",0);
      if fileName then
         if database then
           database:close()
         end
         database=sqlite3.open(fileName)
         connectionStatus:label("Current database is : " .. fileName)
      else
        return
      end
      
      if (not database) then
        fltk.fl_alert("Invalid filename !!")
        connectionStatus:label("No open database")
        return
      end
      
      dbList:clear()
      tableList = {}
      tableSelect = "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name"
      
      -- First lets check the database is valied (this a wasteful way to do it)
      errorCode = database:exec(tableSelect)
      if (errorCode ~= sqlite3.OK) then
        fltk.fl_alert("Please select another DB - " .. database:errmsg())
        database = nil
        connectionStatus:label("No open database")
        return
      end

      counter=1
      for row in database:rows(tableSelect) do
        dbList:add(unpack(row))
        tableList[counter] = unpack(row) -- Work around for murgaLua < = 0.5 problem.
        counter=counter+1
      end
   end

   if (w:value() == 2) then

      if database then
        database:close()
      end
      
      database=sqlite3:open_memory()
      createDemoDb(database)
      connectionStatus:label("Current database is : IN MEMORY DEMO DATABASE")
      
      dbList:clear()
      tableList = {}
      tableSelect = "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name"
      
      counter=1
      for row in database:rows(tableSelect) do
        dbList:add(unpack(row))
        tableList[counter] = unpack(row) -- Work around for murgaLua < = 0.5 problem.
        counter=counter+1
      end
      
      fltk.fl_alert("Test database created IN MEMORY")
      inputBuffer:text("SELECT article, price FROM invoice_overflow WHERE invoice = 2 ORDER BY id")
   end

   if (w:value() == 3) then
      if database then
        database:close()
      end
      os.exit()
   end

   if (w:value() == 5) then
     resultStr = ""
     
     if database then
       stmt = database:prepare(inputBuffer:text())
       
       if (stmt == null) then
          fltk.fl_alert(database:errmsg())
          return
       end
     
       if ( 0 < # stmt:get_names()) then
         resultStr = formatSelectResults(stmt)
       else
         -- stmt:step() DOESN'T SEEM TO ALLOW MULTIPLE STATEMENTS
         database:exec(inputBuffer:text()) -- This allows the us to run lots of DDL and stuff
         resultStr = "Last statement updated " .. database:changes() .. " rows ..."
         
         if (database:errmsg() ~= "not an error") then
           resultStr = resultStr .. "\n" .. database:errmsg()
         end
       end

       stmt:finalize()
       outputBuffer:text(resultStr)
     else
       fltk.fl_alert("Please select a database")
     end
   end

end

dbList:callback(table_callback);
menuBar:callback(menu_callback);

menuBar:add("File/&Open or Create DB");
menuBar:shortcut(1, fltk.FL_ALT + string.byte("o"));
menuBar:add("File/&Create and open demo DB");
menuBar:shortcut(2, fltk.FL_ALT + string.byte("c"));
menuBar:add("File/E&xit");
menuBar:shortcut(3, fltk.FL_ALT + string.byte("x"));
menuBar:add("&Execute query");
menuBar:shortcut(5, fltk.FL_ALT + string.byte("e"));

window:show();
Fl:run();
