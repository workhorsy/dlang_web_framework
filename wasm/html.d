// Copyright (c) 2022 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
// Licensed under the MIT License
// A Dlang web framework
// https://github.com/workhorsy/dlang_web_framework

version (WebAssembly) {
} else {
	static assert(0, "This module should only be used with WebAssembly.");
}

extern(C):

// FIXME: Move into module instead of struct
static struct console {
	static void log(string message) {
		import helpers : d_memory_copy;
		d_memory_copy(message, _arg1.memory, _arg1.len);
		js_console_log(_arg1.memory.ptr, _arg1.len);
	}
}

// FIXME: Move into module instead of struct
static struct document {
	static HtmlElement querySelector(string query) {
		import helpers : d_memory_copy;
		d_memory_copy(query, _arg1.memory, _arg1.len);
		long id = js_document_querySelector(_arg1.memory.ptr, _arg1.len);
		if (id != -1) {
			HtmlElement element = HtmlElement(id);
			return element;
		} else {
			return HtmlElement.init;
		}
	}
}


size_t _fetch_id;
void delegate(string text)[1024] _fetch_cbs;

void fetch(string uri, void delegate(string text) cb) {
	import helpers : d_memory_copy;

	size_t id = _fetch_id++;
	_fetch_cbs[id] = cb;

	d_memory_copy(uri, _arg1.memory, _arg1.len);
	js_fetch(id, _arg1.memory.ptr, _arg1.len);
}

void fetch_cb(size_t id, const char* uri_ptr, size_t uri_len, const char* text_ptr, size_t text_len) {
	//console.log("AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA fetch_cb");
	string uri = cast(string) uri_ptr[0 .. uri_len-1];
	string text = cast(string) text_ptr[0 .. text_len-1];
	//console.log(uri);
	//console.log(text);
	_fetch_cbs[id](text);
}

struct Arg {
	char[1024] memory = 0;
	size_t len = 1024;
}

struct HtmlElement {
	long id;

	void addEventListener(string event_name, string function_name) {
		import helpers : d_memory_copy;
		d_memory_copy(event_name, _arg1.memory, _arg1.len);
		d_memory_copy(function_name, _arg2.memory, _arg2.len);
		js_element_addEventListener(id, _arg1.memory.ptr, _arg1.len, _arg2.memory.ptr, _arg2.len);
	}
}

private:

void js_console_log(const char* s, size_t len);
size_t js_document_querySelector(const char* s, size_t len);
void js_element_addEventListener(long id, char* event_name, size_t event_name_len, char* function_name, size_t function_name_len);
void js_fetch(size_t id, const char* s, size_t len);

Arg _arg1;
Arg _arg2;
