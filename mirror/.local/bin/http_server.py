#!/usr/bin/env python3

import sys

import http.server
from http import HTTPStatus

def update(d, k, v):
    print(d)
    d[k] = v
    return d

class MyBaseHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    extensions_map = update(http.server.SimpleHTTPRequestHandler.extensions_map, ".wasm", "application/wasm")
    #  extensions_map["wasm"] = "application/wasm"

    #  def do_GET(self):
        #  #  self.send_header(keyword, value)
        #  #  self.send_response(
        #  #  self.end_headers()

        #  self.log_message("yam")
        #  self.send_response(HTTPStatus.OK)
        #  #  self.send_header("Content-type", "text/html; charset=%s" % enc)
        #  self.send_header("Content-type", "text/html; charset=utf8")
        #  data = bytes("a", "utf8")
        #  print(data)
        #  self.send_header("Content-Length", str(len(data)))
        #  print(type(self.wfile))
        #  #  self.wfile.seek(0)
        #  self.end_headers()
        #  self.wfile.write(data)

def main(argv):

    #  print(dir(HTTPStatus))
    address = ("", 8080)
    httpd = http.server.HTTPServer(address, MyBaseHTTPRequestHandler)

    httpd.serve_forever()

if __name__ == "__main__":
    sys.exit(main(sys.argv))
