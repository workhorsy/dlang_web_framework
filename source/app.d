// Copyright (c) 2022 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
// This file is licensed under the MIT License
// https://github.com/workhorsy/dlang_web_framework


import mime_types : mime_type_map;
import http_request : HttpRequest;
import http_server : HttpServer;
import std.string : format;
import fcgi : fcgi_init;


int main() {
	fcgi_init();

	auto server = new HttpServer("Dlang HTTP Server");
	HttpRequest request;
	ushort status;
	while (server.accept_request(request, status)) {
		//fcgi_printf("!!!! request: %s\n".format(request));

		// Handle errors parsing request
		switch (status) {
			case 413:
				string message = "413 Request Entity Too Large: The HTTP header is bigger than the max header size.";
				server.write_response(request, status, mime_type_map["text"], message);
				continue;
			case 415:
				string message = "415 Unsupported Media Type: The server does not understand the '%s' format.".format(request.format);
				server.write_response(request, status, mime_type_map["text"], message);
				continue;
			default:
				break;
		}

		// Handle requests
		if (request.method == "GET" && request.uri == "/index.html" || request.uri == "/") {
			server.write_file(request, status, mime_type_map["html"], "index.html");
		} else if (request.method == "GET" && request.uri == "/wasm.wasm") {
			server.write_file(request, status, mime_type_map["wasm"], "wasm.wasm");
		} else {
			server.write_response(request, status, mime_type_map["text"], "Unknown route");
		}
	}

	return 0;
}
