// Copyright (c) 2022 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
// Licensed under the MIT License
// A Dlang web framework
// https://github.com/workhorsy/dlang_web_framework



import http_request;
import std.traits : isSomeString;

class HttpServer {
	import fcgi;
	import std.digest.sha;

	bool _is_fcgi = true;
	//bool _is_production = false;
	string _server_name = "Dlang HTTP Server";
	SHA1Digest _sha_encoder;

	// FIXME: Session info needs to be preserved between runs
	int _session_id = 0;
	string _salt;
	string[string][string] _sessions;

	this(string server_name) {
		_server_name = server_name;
		_sha_encoder = new SHA1Digest();
	}

	bool accept() {
		return fcgi_accept();
	}

	HttpRequest read_request(out ushort status) {
		string raw_request = fcgi_get_env_request();
		return parse_http_request_header(raw_request, status);
	}

	void write_response(S)(HttpRequest request, ushort status_code, string content_type, S text)
	if (isSomeString!S) {
		string response_header = generate_http_response_header(request, _is_fcgi, _server_name, status_code, content_type, text);
		fcgi_write_stdout(response_header);
		fcgi_write_stdout(text);
	}

	void write_file(HttpRequest request, ushort status_code, string content_type, string file_name) {
		//server.write_response(request, status, mime_type_map["wasm"], cast(ubyte[]) read("wasm.wasm"));
		import std.file : read;
		import std.stdio : File;

		// FIXME: Change this to use a pre allocated buffer and stream the file
		auto f = File(file_name, "rb");
		char[] content = new char[f.size()];
		{
			scope (exit) f.close();
			f.rawRead(content);
		}

		this.write_response(request, status_code, content_type, content);
	}

/+
	string hash_and_base64(string value, string salt) {
		import std.digest.sha;
		import std.base64 : Base64;
		// Salt and hash the string
		ubyte[] shaed = _sha_encoder.digest(value ~ salt);

		// Base64 the string and return it
		const(char)[] b64ed = Base64.encode(shaed);
		return cast(string) b64ed;
	}

	string render_text(HttpRequest request, string text, ushort status_code = 200, string format = null) {
		import std.range : padLeft;
		import std.conv : to;

		if (format==null) format = request.format;
		if (format==null) format = "txt";
		string content_type = mime_type_map[format];

		// If a 404 page is less than 512 bytes, we pad it for Chrome/Chromium
		// Otherwise the "Friendly 404" will show in the browser.
		// https://bugs.chromium.org/p/chromium/issues/detail?id=1695
		if (status_code == 404 && text.length < 512)
			text = text.padLeft(' ', 512).to!string;

		return generate_text(request, text, status_code, content_type);
	}

	string generate_text(HttpRequest request, string text, ushort status_code, string content_type) {
		import std.string : format;
		import std.stdio;

		// Get the status code
		string status = get_verbose_status_code(status_code);

		import std.datetime.systime : SysTime, Clock;
		import std.datetime.date : DateTime;
		SysTime now = Clock.currTime();
		// FIXME: Uses wrong date format
		// Mon, 23 May 2005 22:38:34 GMT
		string http_version = _is_fcgi ? "" : "HTTP/1.1 ";
		string retval =
		"%s%s\r\n".format(http_version, status) ~
		"Date: %s%s%s\r\n".format(now.toSimpleString()) ~
		"Server: %s\r\n".format(_server_name);

		// Get all the new cookie values to send
		foreach (string name, string value ; request._cookies) {
			retval ~= "Set-Cookie: %s=%s\r\n".format(name, escape(cast(char[]) value));
		}

		retval ~= "Status: %s\r\n".format(status);
		//"X-Runtime: 0.15560\r\n",
		//"ETag: \"53e91025a55dfb0b652da97df0e96e4d\"\r\n",
		retval ~=
		"Access-Control-Allow-Origin: *\r\n" ~
		"Cache-Control: private, max-age=0\r\n" ~
		"Content-Type: %s\r\n".format(content_type) ~
		"Content-Length: %s\r\n".format(retval.length) ~
		//"Vary: User-Agent\r\n",
		"\r\n";

		return retval;
	}

	void trigger_on_request(char[] raw_request) {
		import std.string : indexOf, format, splitLines, split;
		import std.conv : to;

		//write_to_log(raw_request);
		auto request = new HttpRequest();
		_response = null;
		char[] _fcgi_raw_body = null;
		int len = 0;

		// Read the request header
		ptrdiff_t header_end = raw_request.indexOf("\r\n\r\n");

		// If we have not found the end of the header return a 413 error
		if (header_end == -1) {
			_response = cast(char[]) render_text(request, "413 Request Entity Too Large: The HTTP header is bigger than the max header size of %s bytes.".format(_buffer.length), 413);
			return;
		}

		// Get the raw header from the buffer
		string raw_header = cast(string) raw_request[0 .. header_end];

		// Get the header info
		string[] header_lines = raw_header.splitLines();
		string[] first_line = header_lines[0].split(" ");
		request.method = first_line[0];
		request.uri = first_line[1];
		request.format = before(after_last(after_last(request.uri, "/"), "."), "?");
		request.was_format_specified = (request.format != "");
		if (! request.was_format_specified) request.format = "html";
		request.http_version = first_line[2];

		// If the format is unknown, return a 415 error
		if (! (request.format in mime_type_map)) {
			_response = cast(char[]) render_text(request, "415 Unsupported Media Type: The server does not understand the '%s' format.".format(request.format), 415, "txt");
			return;
		}

		// Get all the fields
		foreach (string line ; header_lines) {
			// Break if we are at the end of the fields
			if (line.length == 0) break;

			string[] _pair;
			if (pair(line, ": ", _pair)) {
				request._fields[_pair[0]] = _pair[1];
			}
		}

		// Determine if the client has cookie support
		bool has_cookie_support = true;
		if ("User-Agent" in request._fields) {
			has_cookie_support = !contains(request._fields["User-Agent"], "ApacheBench");
		}

		// Get the cookies
		if (has_cookie_support && ("Cookie" in request._fields) != null) {
			foreach (string cookie ; split(request._fields["Cookie"], "; ")) {
				string[] _pair;
				if (pair(cookie, "=", _pair)) {
					request._cookies[_pair[0]] = cast(string) unescape(cast(char[])_pair[1]);
				} else {
	//				this.write_to_log("Malformed cookie: " ~ cookie ~ "\n");
				}
			}
		}

		// Get the HTTP GET params
		if (contains(request.uri, "?")) {
			foreach (string param ; split(after(request.uri, "?"), "&")) {
				string[] _pair;
				if (pair(param, "=", _pair)) {
					request._params[cast(string) unescape(cast(char[]) _pair[0])].value = cast(string) unescape(cast(char[])_pair[1]);
				}
			}
		}

		// Monkey Patch the http method
		// This lets browsers fake http put, and delete
		if (has_cookie_support && request._params.has_key("method")) {
			switch (request._params["method"].value) {
				case "GET":
				case "POST":
				case "PUT":
				case "DELETE":
				case "OPTIONS":
					request.method = request._params["method"].value; break;
				default: break;
			}
		}

		if (request.method == "POST" || request.method == "PUT") {
			// Make sure the Content-Length field exist
			if (! ("Content-Length" in request._fields)) {
				_response = cast(char[]) render_text(request, "411 Length Required: Content-Length is required for HTTP POST and PUT.", 411);
				return;
			}
			request.content_length = request._fields["Content-Length"].to!ushort;

			// Make sure the Content-Type field exist
			if (! ("Content-Type" in request._fields)) {
				_response = cast(char[]) render_text(request, "415 Unsupported Media Type: A valid Content-Type is required for HTTP POST and PUT.", 415);
				return;
			}

			// For cgi read the body into memory
			// FIXME: Puting the whole body into memory is bad.
			if (_is_fcgi) {
				_fcgi_raw_body = new char[request.content_length];
				fcgi_get_stdin(_fcgi_raw_body);
			// Or normally read the body into a file
			} else {
				// FIXME
				/*
				int remaining_length = request.content_length;
				File file = new File("raw_body", File.WriteCreate);
				string body_chunk = raw_request[header_end+4 .. length];
				file.write(body_chunk);
				remaining_length -= body_chunk.length;

				while(remaining_length > 0) {
					len = socket_read(_fd, _file_buffer.ptr, _file_buffer.length);
					body_chunk = _file_buffer[0 .. len];
					file.write(body_chunk);
					remaining_length -= body_chunk.length;
				}

				file.close();
				*/
			}
		}

		// Determine if we have a session id in the cookies
		bool has_session = false;
		has_session = (("_appname_session" in request._cookies) != null);

		// Determine if the session id is invalid
		if (has_cookie_support && has_session && (request._cookies["_appname_session"] in _sessions) == null) {
			string hashed_session_id = request._cookies["_appname_session"];
	//		this.write_to_log("Unknown session id '" ~ hashed_session_id ~ "'\n");
			has_session = false;
		}

		// Create a new session if we need it
		string hashed_session_id = null;
		if (! has_session) {
			// Get the next session_id and increment the sequence
			int new_session_id = _session_id++;

			// Create the hashed session id
			// Don't bother hashing or base64ing the session
			// if it is not going to be used by the client.
			if (has_cookie_support)
				hashed_session_id = hash_and_base64(new_session_id.to!string, _salt);
			else
				hashed_session_id = new_session_id.to!string;
			request._cookies["_appname_session"] = hashed_session_id;

	//		this.write_to_log("Created session number '" ~ to_s(new_session_id) ~ "' '" ~ hashed_session_id ~ "'\n");
		} else {
			hashed_session_id = request._cookies["_appname_session"];
	//		this.write_to_log("Using existing session '" ~ request._cookies["_appname_session"] ~ "'\n");
		}

		// Copy the existing session to the request
		if (hashed_session_id in _sessions)
			request._sessions = _sessions[hashed_session_id];

		// Process the remainder of the request based on its method
		switch (request.method) {
			case "GET":
				_response = cast(char[]) render_text(request, "200: Okay", 200);
				break;
			case "POST":
				_response = cast(char[]) render_text(request, "200: Okay", 200);
				break;
			case "PUT":
				_response = cast(char[]) render_text(request, "200: Okay", 200);
				break;
			case "DELETE":
				_response = cast(char[]) render_text(request, "200: Okay", 200);
				break;
			case "OPTIONS":
				// Send a basic options header for access control
				// See: https://developer.mozilla.org/En/HTTP_Access_Control
				_response = cast(char[])
				(_is_fcgi ? "" : "HTTP/1.1 200 OK\r\n") ~
				"Server: " ~ _server_name ~ "\r\n" ~
				"Status: 200 OK\r\n" ~
				"Access-Control-Allow-Origin: *\r\n" ~
				"Content-Length: 0\r\n" ~
				"\r\n";
				break;
			default:
				throw new Exception("Unknown http request method '%s'.".format(request.method));
		}

		// Copy the modified session back to the sessions
		_sessions[hashed_session_id] = request._sessions;

		// FIXME: this prints out all the values we care about
		/*
		this.write_to_log("Sessions { :\n");
		foreach (string n, string[string] values ; _sessions) {
			this.write_to_log("\t" ~ n ~ "\n");
			foreach (string name, string value ; values) {
				this.write_to_log("\t\t" ~ name ~ " => " ~ value ~ "\n");
			}
		}
		this.write_to_log("}\n");
		*/
	}
+/
}

HttpRequest parse_http_request_header(string raw_request, out ushort status) {
	import helpers;
	import mime_types;
	import std.string : indexOf, format, splitLines, split;
	import std.conv : to;

	//write_to_log(raw_request);
	auto request = new HttpRequest();
	int len = 0;

	// Read the request header
	ptrdiff_t header_end = raw_request.indexOf("\r\n\r\n");

	// If we have not found the end of the header return a 413 error
	if (header_end == -1) {
		status = 413;
		//_response = cast(char[]) render_text(request, "413 Request Entity Too Large: The HTTP header is bigger than the max header size of %s bytes.".format(_buffer.length), 413);
		return request;
	}

	// Get the raw header from the buffer
	string raw_header = raw_request[0 .. header_end];

	// Get the header info
	string[] header_lines = raw_header.splitLines();
	string[] first_line = header_lines[0].split(" ");
	request.method = first_line[0];
	request.uri = first_line[1];
	request.format = request.uri.after_last("/").after_last(".").before("?");
	request.was_format_specified = (request.format != "");
	if (! request.was_format_specified) request.format = "html";
	request.http_version = first_line[2];

	// If the format is unknown, return a 415 error
	if (request.format !in mime_type_map) {
		status = 415;
		//_response = cast(char[]) render_text(request, "415 Unsupported Media Type: The server does not understand the '%s' format.".format(request.format), 415, "txt");
		return request;
	}

	// Get all the fields
	foreach (string line ; header_lines) {
		// Break if we are at the end of the fields
		if (line.length == 0) break;

		string[] _pair;
		if (pair(line, ": ", _pair)) {
			request._fields[_pair[0]] = _pair[1];
		}
	}

	// Determine if the client has cookie support
	bool has_cookie_support = true;
	if ("User-Agent" in request._fields) {
		has_cookie_support = ! request._fields["User-Agent"].contains("ApacheBench");
	}

	// Get the cookies
	if (has_cookie_support && ("Cookie" in request._fields) != null) {
		foreach (string cookie ; request._fields["Cookie"].split("; ")) {
			string[] _pair;
			if (cookie.pair("=", _pair)) {
				request._cookies[_pair[0]] = unescape(_pair[1]);
			} else {
//				this.write_to_log("Malformed cookie: " ~ cookie ~ "\n");
			}
		}
	}

	// Get the HTTP GET params
	if (request.uri.contains("?")) {
		foreach (string param ; request.uri.after("?").split("&")) {
			string[] _pair;
			if (param.pair("=", _pair)) {
				request._params[unescape(_pair[0])].value = unescape(_pair[1]);
			}
		}
	}

	// Monkey Patch the http method
	// This lets browsers fake http put, and delete
	if (has_cookie_support && request._params.has_key("method")) {
		switch (request._params["method"].value) {
			case "GET":
			case "POST":
			case "PUT":
			case "DELETE":
			case "OPTIONS":
				request.method = request._params["method"].value; break;
			default: break;
		}
	}

	status = 200;
	return request;
}

string generate_http_response_header(S)(HttpRequest request, bool is_fcgi, string server_name, ushort status, string content_type, S text)
if (isSomeString!S) {
	import helpers;
	import http_status_code;
	import std.string : format;
	import std.stdio;
	import std.datetime.systime : SysTime, Clock;
	import std.datetime.date : DateTime;

	// Get the status code
	string status_message = get_verbose_status_code(status);

	SysTime now = Clock.currTime();
	// FIXME: Uses wrong date format
	// Mon, 23 May 2005 22:38:34 GMT
	string http_version = is_fcgi ? "HTTP/1.1 " : "HTTP/1.1 ";
	string retval =
	"%s%s\r\n".format(http_version, status_message) ~
	"Date: %s\r\n".format(now.toSimpleString()) ~
	"Server: %s\r\n".format(server_name);

	// Get all the new cookie values to send
	foreach (string name, string value ; request._cookies) {
		retval ~= "Set-Cookie: %s=%s\r\n".format(name, escape(value));
	}

	retval ~= "Status: %s\r\n".format(status);
	//"X-Runtime: 0.15560\r\n",
	//"ETag: \"53e91025a55dfb0b652da97df0e96e4d\"\r\n",
	retval ~=
	"Access-Control-Allow-Origin: *\r\n" ~
	"Cache-Control: private, max-age=0\r\n" ~
	"Content-Type: %s\r\n".format(content_type) ~
	"Content-Length: %s\r\n".format(text.length) ~
	//"Vary: User-Agent\r\n",
	"\r\n";

	return retval;
}
