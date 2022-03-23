// Copyright (c) 2022 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
// This file is licensed under the MIT License
// https://github.com/workhorsy/dlang_web_framework

import helpers;
import mime_types;
import http_status_code;
import http_request;
import http_server;
import std.string : format;
import fcgi;


int main() {
	fcgi_init();

	auto server = new HttpServer("Dlang HTTP Server");
	HttpRequest request;
	ushort status;
	while (server.accept_request(request, status)) {
		fcgi_printf("!!!! request: %s\n".format(request));

		// Handle errors parsing request
		switch (status) {
			case 413:
				string message = "413 Request Entity Too Large: The HTTP header is bigger than the max header size.";
				server.write_response(request, status, "text/plain", message);
				continue;
			case 415:
				string message = "415 Unsupported Media Type: The server does not understand the '%s' format.".format(request.format);
				server.write_response(request, status, "text/plain", message);
				continue;
			default:
				break;
		}

		// Handle requests
		if (request.method == "GET" && request.uri == "/blah") {
			server.write_response(request, status, "text/plain", "Blah engaged");
		} else {
			server.write_response(request, status, "text/plain", "Unknown route");
		}
	}

	return 0;
}
