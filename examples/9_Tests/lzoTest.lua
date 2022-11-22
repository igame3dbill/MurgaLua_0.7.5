	in_filename  = "lzoTest.lua"
	out_filename = "lzoTest.lzo"
	inf  = io.open(in_filename,  "rb")
	outf = io.open(out_filename, "wb")

	-- Read, compress & write
	outf:write(lzo.compress(inf:read("*a")))

	outf:close()
	inf:close()

	in_filename  = "lzoTest.lzo"
	out_filename = "lzoTest.new"
	inf  = io.open(in_filename,  "rb")
	outf = io.open(out_filename, "wb")

	-- Read, de-compress & write
	outf:write(lzo.decompress(inf:read("*a")))
	outf:close()
	inf:close()
