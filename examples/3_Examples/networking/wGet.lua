

function webGet ( targetURL, fileHandle, proxyServer, httpHeaders, followRedirects )
	
	local http		= require('socket.http')
	local ltn12 	= require("ltn12")
	
	if followRedirects == nil then
	    redirectFollow = true
	end
	
	if httpHeaders == nil then
	    httpHeaders =
	    	{
	    		["Useragent"]		= 'Mozilla/5.0 (compatible;MSIE 7.0;Windows NT 6.0)',
	    		["Accept-Encoding"] = "gzip,deflate",
	    		["Connection"]		= "Keep-Alive"
			}
	end

	local responseBody, responseStatusCode, responseHeaders, responseStatusLine =
		http.request
		{
		  method	= "GET",
		  header	= httpHeaders,
		  url		= targetURL,
		  proxy		= proxyServer,
		  redirect	= redirectFollow,
		  sink		= ltn12.sink.file(fileHandle)
		}
		
	return responseStatusCode, responseHeaders
end

