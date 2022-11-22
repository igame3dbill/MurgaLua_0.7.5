#!/opt/selene/bin/lua
--
--	test selene crypto functions
--	$Id: cryptest,v 1.1 2006/04/19 15:24:10 erik Exp $
--[[
crypto.sha1(data)
	returns the 5*4 byte SHA1 digest as 40 byte uppercase (bigendian) hex (%08X)
crypto.sha1(data, state)
	if data length is a multiple of 64 byte and not 0,
		returns a state, which is a string of digest, blank and a decimal number
	else only the digest
	use "" as initial state
For more information on SHA-1 see http://ietf.org/rfc/rfc3174.txt
Since Feb 15th 2005 SHA-1 is considered "broken"
c.f http://www.schneier.com/blog/archives/2005/02/sha1_broken.html

However, for some years to come and the level of security possible in
a Lua environment, it can probably still be considered sufficient ...
Probably we should also support whirlpool?
http://planeta.terra.com.br/informatica/paulobarreto/hflounge.html


crypto.blowfish(key[, initvector [,byteorder] ])
	returns a function bf doing blowfish (an 8-byte block cipher) in CBC mode
	initvector is a cipherblock represented as 16 hex digits
	byteorder defaults to bigendian,
		only first char is significant: b[ig]|l[ittle]|n[ative]|s[wap]
the function is used as
bf(data [,decode])
	data and the returned string are raw bytes
	if data length is not a multiple of 8 bytes, it's padded with 0 bytes
	decode is boolean, default is encode
For more information on blowfish see http://www.schneier.com/blowfish.html

These functions make no attempt to wipe their traces from memory,
as this would be rather futile in a Lua environment.
]]

local sprintf = string.format
local function printf (fmt, ...) return print(sprintf(fmt, ...)) end

local function check (test, ok, got)
	if ok == got then return printf("ok  %s = %s",test,ok) end
	return printf("NOK %s = %s GOT '%s'",test, ok, got or "<nil>")
end

-- SHA1 test vectors from http://www.itl.nist.gov/fipspubs/fip180-1.htm
local md = {
	["abc"] = "A9993E364706816ABA3E25717850C26C9CD0D89D",
	["abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"]
		= "84983E441C3BD26EBAAE4AA1F95129E5E54670F1",
	[string.rep("a",1000000)] = "34AA973CD4C4DAA4F61EEB2BDBAD27316534016F"
}

for message,digest in pairs(md) do
	dig = crypto.sha1(message)
	msg = message -- must not touch message here
	if 60 < string.len(msg) then
		msg = string.sub(msg,1,57).."..."
	end
	check(sprintf("sha1('%s')",msg), digest, dig)
end


-- sha1 with state
local lengths = {62,63,64,65,100,127,128,129,1000,1000000}
for _,len in pairs(lengths) do
	digest = crypto.sha1(string.rep("a",len))
	if len > 8192 then
		decr = 8192
	elseif len > 128 then
		decr = 128
	else
		decr = 64
	end
	msg = string.rep("a",decr)
	rem = len -- remaining length
	dig = ""
	-- eats multiples of 64 bytes; closes on odd or empty block
	repeat
		if rem < decr then msg = string.rep("a",rem) end
		dig = crypto.sha1(msg, dig)
		-- print("state is "..dig)
		rem = rem - decr
	until 40 == string.len(dig)
	check(sprintf("sha1('a'*%d)",len), digest, dig)
end
print ""



local function hexdump (bin)
	return (string.gsub(bin, ".", function (c)
		return string.format("%02X", string.byte(c))
		end))
end
local function hexval (val) -- val is string.byte(hexdigit)
	val = val - 48 -- '0'-'9' -> 0-9
	if 16 < val then
		val = val-7
		if 32 < val then val = val-32 end
	end
	return val
end
local function hexscan (hex)
	return (string.gsub(hex, "..", function (xx)
		local hi,lo = string.byte(xx,1,2)
		return string.char(hexval(hi)*16+hexval(lo))
		end))
end
-- print(hexdump("JAJA"))
-- print(hexscan("4A414a41"))

-- Eric Young's Blowfish test vectors from http://schneier.com/code/vectors.txt
eyoung = { -- key clear cipher
	{"0000000000000000","0000000000000000","4EF997456198DD78"},
	{"FFFFFFFFFFFFFFFF","FFFFFFFFFFFFFFFF","51866FD5B85ECB8A"},
	{"3000000000000000","1000000000000001","7D856F9A613063F2"},
	{"1111111111111111","1111111111111111","2466DD878B963C9D"},
	{"0123456789ABCDEF","1111111111111111","61F9C3802281B096"},
	{"1111111111111111","0123456789ABCDEF","7D0CC630AFDA1EC7"},
	{"0000000000000000","0000000000000000","4EF997456198DD78"},
	{"FEDCBA9876543210","0123456789ABCDEF","0ACEAB0FC6A0A28D"},
	{"7CA110454A1A6E57","01A1D6D039776742","59C68245EB05282B"},
	{"0131D9619DC1376E","5CD54CA83DEF57DA","B1B8CC0B250F09A0"},
	{"07A1133E4A0B2686","0248D43806F67172","1730E5778BEA1DA4"},
	{"3849674C2602319E","51454B582DDF440A","A25E7856CF2651EB"},
	{"04B915BA43FEB5B6","42FD443059577FA2","353882B109CE8F1A"},
	{"0113B970FD34F2CE","059B5E0851CF143A","48F4D0884C379918"},
	{"0170F175468FB5E6","0756D8E0774761D2","432193B78951FC98"},
	{"43297FAD38E373FE","762514B829BF486A","13F04154D69D1AE5"},
	{"07A7137045DA2A16","3BDD119049372802","2EEDDA93FFD39C79"},
	{"04689104C2FD3B2F","26955F6835AF609A","D887E0393C2DA6E3"},
	{"37D06BB516CB7546","164D5E404F275232","5F99D04F5B163969"},
	{"1F08260D1AC2465E","6B056E18759F5CCA","4A057A3B24D3977B"},
	{"584023641ABA6176","004BD6EF09176062","452031C1E4FADA8E"},
	{"025816164629B007","480D39006EE762F2","7555AE39F59B87BD"},
	{"49793EBC79B3258F","437540C8698F3CFA","53C55F9CB49FC019"},
	{"4FB05E1515AB73A7","072D43A077075292","7A8E7BFA937E89A3"},
	{"49E95D6D4CA229BF","02FE55778117F12A","CF9C5D7A4986ADB5"},
	{"018310DC409B26D6","1D9D5C5018F728C2","D1ABB290658BC778"},
	{"1C587F1C13924FEF","305532286D6F295A","55CB3774D13EF201"},
	{"0101010101010101","0123456789ABCDEF","FA34EC4847B268B2"},
	{"1F1F1F1F0E0E0E0E","0123456789ABCDEF","A790795108EA3CAE"},
	{"E0FEE0FEF1FEF1FE","0123456789ABCDEF","C39E072D9FAC631D"},
	{"0000000000000000","FFFFFFFFFFFFFFFF","014933E0CDAFF6E4"},
	{"FFFFFFFFFFFFFFFF","0000000000000000","F21E9A77B71C49BC"},
	{"0123456789ABCDEF","0000000000000000","245946885754369A"},
	{"FEDCBA9876543210","FFFFFFFFFFFFFFFF","6B5C5A9C5D9E0A5A"},
}
local key,clear,cipher
for _,kcc in ipairs(eyoung) do
	key,clear,cipher = unpack(kcc)
	local bf,badkey = crypto.blowfish(hexscan(key))
	check(sprintf("blowfish('%s')('%s')",key,clear), cipher,
		hexdump(bf(hexscan(clear))))
	check(sprintf("blowfish('%s')('%s',true)",key,cipher), clear,
		hexdump(bf(hexscan(cipher),true)))
end

-- Young's CBC test with init vector
key = "0123456789ABCDEFF0E1D2C3B4A59687"
init = "FEDCBA9876543210"
clear = "37363534333231204E6F77206973207468652074696D6520666F722000"
cipher = "6B77B4D63006DEE605B156E27403979358DEB9E7154616D959F1652BD5FF92CC"
check(sprintf("blowfish('%s','%s')('%s')",key,init,clear), cipher,
	hexdump(crypto.blowfish(hexscan(key),init)(hexscan(clear))))

print ""

-- byteorders, parts and init vectors
local alphabet = "0123456789abcdefghijklmnopqrstuvwxyz"
for _,bo in ipairs({"little", "big"}) do
	-- 36 chars should be padded to 5 8byte blocks
	realcipher =
		crypto.blowfish("TESTKEY",nil,bo)(alphabet)
	cipher = hexdump(realcipher)
	bf,badkey = crypto.blowfish("TESTKEY",nil,bo)
	if badkey then q="bad" else q="good" end
	printf("ok BF %s: %s TESTKEY is %s",bo,cipher,q)

	-- single blocks
	local off = 1
	for _,part in ipairs({"01234567","89abcdef","ghijklmn","opqrstuv","wxyz"}) do
		check(sprintf("blowfish part %d",off), string.sub(cipher, off, off+15),
			hexdump(bf(part)))
		off = off+16
	end

	-- double blocks
	bf = crypto.blowfish("TESTKEY",nil,bo) -- reset
	off = 1
	for _,part in ipairs({"0123456789abcdef","ghijklmnopqrstuv","wxyz"}) do
		check(sprintf("blowfish part %d",off), string.sub(cipher, off, off+31),
			hexdump(bf(part)))
		off = off+32
	end

	-- with init
	bf = crypto.blowfish("TESTKEY",string.sub(cipher,1,16),bo)
	local off = 17
	for _,part in ipairs({"89abcdef","ghijklmn","opqrstuv","wxyz"}) do
		check(sprintf("blowfish part %d",off), string.sub(cipher, off, off+15),
			hexdump(bf(part)))
		off = off+16
	end

	-- decoding
	bf = crypto.blowfish("TESTKEY",nil,bo)
	check("blowfish decode", alphabet.."\0\0\0\0", bf(realcipher,true))

	-- decoding 2nd & 3rd code block using 1st as iv
	bf = crypto.blowfish("TESTKEY",string.sub(cipher,1,16),bo)
	check("blowfish decode", "89abcdefghijklmn",
		bf(string.sub(realcipher,9,24),true))
end



--time
print("timing sha1 1000*100K...")
local hundredk = string.rep("a",102400)
now = os.clock()
for i = 1,1000 do crypto.sha1(hundredk) end
print("ok SHA1 time: ",  os.clock()-now)
print ""

print "timing blowfish 1000*100K..."
bf = crypto.blowfish("TESTKEY",nil,"n") -- native byteorder
now = os.clock()
for i = 1,1000 do bf(hundredk) end
print("ok blowfish time: ",  os.clock()-now)
print ""
