// Copyright (c) 2022 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
// Licensed under the MIT License
// A Dlang web framework
// https://github.com/workhorsy/dlang_web_framework


class HttpRequest {
	import helpers : Dictionary;

	this(string method, string uri, string format, string http_version, Dictionary params, string[string] fields, string[string] cookies) {
		_method = method;
		_uri = uri;
		_format = format;
		_http_version = http_version;
		_params = params;
		_fields = fields;
		_cookies = cookies;
	}

	this() {
		_params = new Dictionary();
	}

	bool was_format_specified() { return _was_format_specified; }
	string method() { return _method; }
	string uri() { return _uri; }
	string format() { return _format; }
	string http_version() { return _http_version; }
	uint content_length() { return _content_length; }

	void was_format_specified(bool value) { _was_format_specified = value; }
	void method(string value) { _method = value; }
	void uri(string value) { _uri = value; }
	void format(string value) { _format = value; }
	void http_version(string value) { _http_version = value; }
	void content_length(uint value) { _content_length = value; }

	Dictionary _params;
	string[string] _fields;
	string[string] _cookies;
	string[string] _sessions;

private:

	bool _was_format_specified;
	string _method = null;
	string _uri = null;
	string _format = null;
	string _http_version = null;
	uint _content_length = 0;
}
