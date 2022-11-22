	in_filename  = "../LICENSE-GPL"
	out_filename = "test.lzo"
	inf  = io.open(in_filename,  "rb")
	outf = io.open(out_filename, "wb")

	-- Read, compress & write
	outf:write(lzo.compress(inf:read("*a")))

	outf:close()
	inf:close()

	in_filename  = "test.lzo"
	out_filename = "LICENSE-GPL"
	inf  = io.open(in_filename,  "rb")
	outf = io.open(out_filename, "wb")

	-- Read, de-compress & write
	outf:write(lzo.decompress(inf:read("*a")))
	outf:close()
	inf:close()
