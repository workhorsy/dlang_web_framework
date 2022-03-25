// Copyright (c) 2022 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
// This file is licensed under the MIT License
// https://github.com/workhorsy/dlang_web_framework

import std.traits : isSomeString;

int fcgi_init() {
	return c_fcgi_init();
}

bool fcgi_accept(out string request) {
	import std.process : environment;
	import std.string : format;

	// Just return false on no connections
	if (c_fcgi_accept() < 0)
		return false;

	// Get the request data from the fcgi server
	// These are called Standard CGI environment variables
	string REQUEST_METHOD = environment.get("REQUEST_METHOD");
	string REQUEST_URI = environment.get("REQUEST_URI");
	string HTTP_USER_AGENT = environment.get("HTTP_USER_AGENT");
	string HTTP_COOKIE = environment.get("HTTP_COOKIE");
	string REMOTE_ADDR = environment.get("REMOTE_ADDR");
	string HTTP_REFERER = environment.get("HTTP_REFERER");
	string HTTP_HOST = environment.get("HTTP_HOST");
	string CONTENT_LENGTH = environment.get("CONTENT_LENGTH");
	string CONTENT_TYPE = environment.get("CONTENT_TYPE");

	// Reconstruct the request
	request = "%s %s HTTP/1.1\r\n".format(REQUEST_METHOD, REQUEST_URI);
	if (HTTP_HOST) request ~= "Host: %s\r\n".format(HTTP_HOST);
	if (HTTP_USER_AGENT) request ~= "User-Agent: %s\r\n".format(HTTP_USER_AGENT);
	if (HTTP_COOKIE) request ~= "Cookie: %s\r\n".format(HTTP_COOKIE);
	if (REMOTE_ADDR) request ~= "Remove-Addr: %s\r\n".format(REMOTE_ADDR);
	if (HTTP_REFERER) request ~= "Referer: %s\r\n".format(HTTP_REFERER);
	if (CONTENT_TYPE) request ~= "Content-Type: %s\r\n".format(CONTENT_TYPE);
	if (CONTENT_LENGTH) request ~= "Content-Length: %s\r\n".format(CONTENT_LENGTH);
	request ~= "\r\n";

	return true;
}

void fcgi_printf(S)(S message)
if (isSomeString!S) {
	c_fcgi_printf(message.ptr);
}

void fcgi_get_stdin(S)(S buffer)
if (isSomeString!S) {
	c_fcgi_get_stdin(buffer.ptr, buffer.length);
}

void fcgi_write_stdout(S)(S message)
if (isSomeString!S) {
	c_fcgi_write_stdout(message.ptr, message.length);
}

void fcgi_write_stderr(S)(S message)
if (isSomeString!S) {
	c_fcgi_write_stderr(message.ptr, message.length);
}

void fcgi_puts(S)(S message)
if (isSomeString!S) {
	c_fcgi_puts(cast(char*) message.ptr);
}

private:

extern (C):

int c_fcgi_init();
void c_fcgi_write_stdout(const char* message, size_t length);
void c_fcgi_write_stderr(const char* message, size_t length);
int c_fcgi_accept();
void c_fcgi_printf(const char* message);
void c_fcgi_puts(const char* message);
void c_fcgi_get_stdin(char* buffer, size_t len);
