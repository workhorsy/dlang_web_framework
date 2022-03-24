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
		//fcgi_printf("!!!! request: %s\n".format(request));

		// Handle errors parsing request
		switch (status) {
			case 413:
				string message = "413 Request Entity Too Large: The HTTP header is bigger than the max header size.";
				server.write_response(request, status, mime_type_map["text"], cast(char[]) message);
				continue;
			case 415:
				string message = "415 Unsupported Media Type: The server does not understand the '%s' format.".format(request.format);
				server.write_response(request, status, mime_type_map["text"], cast(char[]) message);
				continue;
			default:
				break;
		}

		// Handle requests
		if (request.method == "GET" && request.uri == "/index.html" || request.uri == "/") {
			respond_with_file("index.html", mime_type_map["html"]);
		} else if (request.method == "GET" && request.uri == "/wasm.wasm") {
			respond_with_file("wasm.wasm", mime_type_map["wasm"]);
		} else {
			server.write_response(request, status, mime_type_map["text"], "Unknown route");
		}
	}

	return 0;
}

void respond_with_file(string file_name, string mime_type) {
	//server.write_response(request, status, mime_type_map["wasm"], cast(ubyte[]) read("wasm.wasm"));
	import std.file : read;
	import std.stdint;
	import std.stdio : File;

	// FIXME: Change this to use a pre allocated buffer and stream the file
	auto f = File(file_name, "rb");
	ubyte[] content = new ubyte[f.size()];
	{
		scope (exit) f.close();
		f.rawRead(content);
	}

	// FIXME: Change this to use the D server.write_response instead of the C fcgi functions
	string message =
	//"HTTP/1.1 200 OK\r\n" ~
	"Status: 200\r\n" ~
	"Access-Control-Allow-Origin: *\r\n" ~
	"Cache-Control: private, max-age=0\r\n" ~
	"Content-Type: %s\r\n".format(mime_type) ~
	"Context-Length: %s\r\n".format(content.length) ~
	"\r\n";

	c_fcgi_write_stdout(cast(char*) message.ptr, message.length);
	c_fcgi_write_stdout(cast(char*) content.ptr, content.length);
}

// FIXME: Remove this as it is already in fcgi.d
extern (C) void c_fcgi_write_stdout(char* message, size_t length);
extern (C) void c_fcgi_puts(char* message);
