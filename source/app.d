// Copyright (c) 2022 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
// Licensed under the MIT License
// A Dlang web framework
// https://github.com/workhorsy/dlang_web_framework


import mime_types : mime_type_map;
import http_request : HttpRequest;
import http_server : HttpServer;
import std.string : format;
import fcgi : fcgi_init;

string get_request_route(HttpRequest request) {
	import std.string : format;
	return "%s:%s".format(request.method, request.uri);
}

bool respond_default_error(HttpServer server, HttpRequest request, ushort status) {
	switch (status) {
		case 413:
			string message = "413 Request Entity Too Large: The HTTP header is bigger than the max header size.";
			server.write_response(request, status, mime_type_map["text"], message);
			return true;
		case 415:
			string message = "415 Unsupported Media Type: The server does not understand the '%s' format.".format(request.format);
			server.write_response(request, status, mime_type_map["text"], message);
			return true;
		default:
			return false;
	}
}

int main() {
	fcgi_init();

	auto server = new HttpServer("Dlang HTTP Server");
	while (server.accept()) {
		ushort status;
		HttpRequest request = server.read_request(status);
		if (respond_default_error(server, request, status)) {
			continue;
		}

		// Handle request depending on route
		string route = get_request_route(request);
		switch (route) {
			case "GET:/user/99":
				server.write_response(request, status, mime_type_map["json"], `{ "name" : "Bobrick", "sex" : "male", "weight" : 200 }`);
				break;
			case "GET:/index.html", "GET:/":
				server.write_file(request, status, mime_type_map["html"], "index.html");
				break;
			case "GET:/wasm.wasm":
				server.write_file(request, status, mime_type_map["wasm"], "wasm.wasm");
				break;
			default:
				server.write_response(request, 404, mime_type_map["text"], "Unknown route");
				break;
		}
	}

	return 0;
}
