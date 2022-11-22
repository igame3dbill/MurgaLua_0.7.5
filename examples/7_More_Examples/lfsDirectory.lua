cDirectory=lfs.currentdir()


function listFolders(path)
local folderList=""
    for file in lfs.dir(path) do
        
        if file ~= "." and file ~= ".." then
            local f = path..'/'..file
            local attr = lfs.attributes (f)
            assert (type(attr) == "table")
             if attr.mode == "directory" then 
               
             folderList=folderList..file.."\n"
             end   
        end
    end
    return folderList
end

function listFiles(path)
local fileList=""
    for file in lfs.dir(path) do
        if file ~= "." and file ~= ".." then
            local f = path..'/'..file
            local attr = lfs.attributes (f)
            assert (type(attr) == "table")
             if attr.mode == "file" then 
              fileList=fileList..file.."\n"
              end   
        end
    end
    return fileList
end


a=listFolders(cDirectory)
print(a)
b=listFiles(cDirectory)
print(b)
