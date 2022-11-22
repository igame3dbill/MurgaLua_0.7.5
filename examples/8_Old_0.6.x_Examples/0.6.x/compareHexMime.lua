if arg[1]==nil then print("You should provide a filename!") return 1 end
binary_name=io.open(arg[1],"rb")
if not binary_name then print("You should provide a valid filename!") return 1 end
print("Load and summing binary data")
binary_data=binary_name:read("*a")
binary_name:close()
binary_size=#binary_data
binary_md5sum=md5.sum(binary_data)
print("encoding, decoding and summing b64 data")
b64_string=(mime.b64(binary_data,nil))
b64_string_size=#b64_string
binary_data_b64=(mime.unb64(b64_string,nil))
binary_b64_md5sum=md5.sum(binary_data_b64)
binary_data_b64=nil
b64_string=nil
collectgarbage()
print("encoding, decoding and summing hex data")
hex_string=murgaLua.encodeDataAsHex(binary_data)
hex_string_size=#hex_string
binary_data_hex=murgaLua.decodeDataFromHex(hex_string)
binary_hex_md5sum=md5.sum(binary_data_hex)
hex_string=nil
binary_data_hex=nil
binary_data=nil
collectgarbage()
if binary_md5sum~=binary_b64_md5sum then print("Something is wrong with the b64 function!") return 1 end
if binary_md5sum~=binary_hex_md5sum then print("Something is wrong with the hex function!") return 1 end
print("The original file size was "..binary_size.." bytes long")
print(string.format("The b64 encoded data is %d bytes long, which is %.2f%% more than the original data",b64_string_size,b64_string_size/binary_size*100-100))
print(string.format("The hex encoded data is %d bytes long, which is %.2f%% more than the original data",hex_string_size,hex_string_size/binary_size*100-100))
print(string.format("The hex encoded string is %.2f%% bigger than the b64 encoded one",hex_string_size/b64_string_size*100-100))
