function createDemoDb(database)

  database:exec[[
    CREATE TABLE customer (
      id		INTEGER PRIMARY KEY, 
      name	VARCHAR(40)
    );
  
    CREATE TABLE invoice (
      id		INTEGER PRIMARY KEY,
      customer	INTEGER NOT NULL,
      title	VARCHAR(80) NOT NULL,
      article1	VARCHAR(40) NOT NULL,
      price1	REAL NOT NULL,
      article2	VARCHAR(40),
      price2	REAL
    );
  
    CREATE TABLE invoice_overflow (
      id		INTEGER PRIMARY KEY,
      invoice	INTEGER NOT NULL,
      article	VARCHAR(40) NOT NULL,
      price	REAL NOT NULL
    );
  
    INSERT INTO customer VALUES(
      1, "Michael" );
  
    INSERT INTO invoice VALUES(
      1, 1, "Computer parts", "harddisc", 89.90, "floppy", 9.99 );
  
    INSERT INTO customer VALUES(
      2, "John" );
  
    INSERT INTO invoice VALUES(
      2, 2, "Somme food", "apples", 2.79, "pears", 5.99 );
  
    INSERT INTO invoice_overflow VALUES(
      NULL, 2, "grapes", 6.34 );
  
    INSERT INTO invoice_overflow VALUES(
      NULL, 2, "strawberries", 4.12 );
  
    INSERT INTO invoice_overflow VALUES(
      NULL, 2, "tomatoes", 6.17 );
  
    INSERT INTO invoice VALUES(
      3, 2, "A new car", "Cybercar XL-1000", 65000.00, NULL, NULL );
  
  ]]

end

function padStringToLength (stringVar, length, character)

  character = character or " "

  for counter=string.len(stringVar),length-1 do
    stringVar = stringVar .. character
  end
  
  return stringVar
end

function formatSelectResults (stmt)

  colNames = stmt:get_names()
  colCount = # colNames
  
  colSizes = {}
  
  for counter=1,colCount do
    colSizes[counter] = string.len(colNames[counter])
  end
  
  for row in stmt:rows() do
  
    for counter=1,colCount do
    
      if (row[counter] == nil) then
        row[counter] = "NULL"
      end
      
      rowSize = string.len(row[counter])
      
      if (colSizes[counter] < rowSize) then
        colSizes[counter] = rowSize
      end
      
    end
    
  end
  
  blankString = ""
  colLines = {}
  
  namesString = ""
  linesString = ""
  
  for counter=1,colCount do
    colNames[counter] = padStringToLength(colNames[counter], colSizes[counter])
    colLines[counter] = padStringToLength(blankString, colSizes[counter], "-")
    namesString = namesString .. " " .. colNames[counter]
    linesString = linesString .. " " .. colLines[counter]
  end
  
  resultString = namesString  .. "\n" .. linesString
  
  for row in stmt:rows() do
    rowString = ""
    for counter=1,colCount do
  
      if (row[counter] == nil) then
        row[counter] = "NULL"
      end
  
      row[counter] =  padStringToLength(row[counter], colSizes[counter])
      rowString = rowString  .. " " .. row[counter]
    end
    resultString = resultString .. "\n" .. rowString
  end
  
  return resultString
   
end

