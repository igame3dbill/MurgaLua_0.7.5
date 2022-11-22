#!/usr/bin/lua

require "mongoose"

local ctx = mg.start{
    document_root = "./bindings/lua",

    cgi_extensions = "lua",
    cgi_interpreter = "/usr/bin/lua",
    --cgi_interpreter = "C:\\Lua\\5.1\\lua.exe",

    user_callback = function(event, request)
        local event_handlers = {
            ['MG_NEW_REQUEST'] = function(request)
                local uri_handlers = {
                    -- example handler displays the contents of the request table
                    ['/'] = function(request)
                        print("HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n")
                        print("<html><body><h1>Request Info</h1><ul>")
                        for k, v in pairs(request) do
                            if "table" == type(v) then
                                print(string.format("<li><b>%s</b>:</li><ul>", k))
                                for k, v in pairs(v) do
                                    print(string.format("<li><b>%s</b>: %s</li>", k, v))
                                end
                                print("</ul>")
                            else
                                print(string.format("<li><b>%s</b>: %s</li>",
                                      k, tostring(v)))
                            end
                        end
                        print("</ul></body></html>")
                        return true
                    end,

                    -- handle a request with a regular function
                    ["/hello"] = function(request)
                        print("HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n")
                        print("<html><body><h1>Hello, world!</h1></body></html>")
                        return true
                    end,

                    -- delegate the request via CGI
                    ["/hello.lua"] = function(request)
                        execute("/hello.lua")
                        return true
                    end,

                    -- delegate the request to a function returned from a Lua script
                    ["/delegate.lua"] = dofile("./bindings/lua/delegate.lua"),

                    -- reload the script on each request to only dynamic changes
                    ["/deferred_delegate.lua"] = function(request)
                        dofile("./bindings/lua/delegate.lua")(request)
                    end,
                }

                return uri_handlers[request.uri] and
                       uri_handlers[request.uri](request)
            end,

            ['MG_HTTP_ERROR'] = function(request)
                local error_handlers = {
                    [404] = function(request)
                        print("HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n")
                        print(string.format('Document %s not found!\n', request.uri))
                        return true
                    end,
                }

                return error_handlers[request.status_code] and
                       error_handlers[request.status_code](request)
            end,

            ['MG_EVENT_LOG'] = function(request)
                return nil
            end,

            ['MG_INIT_SSL'] = function(request)
                return nil
            end,
        }

        return event_handlers[event] and event_handlers[event](request)
    end,
}

-- run until the user presses enter
io.read()

mg.stop(ctx)

