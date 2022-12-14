print("\nMD5 HASH tests")
print("==============")
print("MD5 sum in HEX for \"this is a test\" = \"" .. md5.sumhexa ("this is a test") .. "\"")
print("MD5 sum in BIN for \"this is a test\" = \"" .. md5.sum ("this is a test") .. "\"")
print("")
print("MD5 encryption tests (password \"test\")")
print("====================")
encryptedTest = md5.crypt ("this is a test", "test");
print("Encrypted \"this is a test\" = \"" .. encryptedTest .. "\"")
print("Decrypted \"this is a test\" = \"" .. md5.decrypt (encryptedTest, "test") .. "\"")
print("")
print("HEX Function tests")
print("==================")
hexTest = murgaLua.encodeDataAsHex ("Test - })(:]'[#!");
print("ENCODED \"Test - })(:]'[#!\" = \"" .. hexTest .. "\"")
print("DECODED \"Test - })(:]'[#!\" = \"" .. murgaLua.decodeDataFromHex (hexTest) .. "\"")
print("ENCODED MD5 from before  \" = \"" .. murgaLua.encodeDataAsHex(md5.sum ("this is a test")) .. "\"")
print("")
print("Binary NULLs (0000ACAE00)  = Length (Should be \"5\") : " .. string.len(murgaLua.decodeDataFromHex ("0000ACAE00")))
