// Copyright (c) 2022 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
// This file is licensed under the MIT License
// https://github.com/workhorsy/dlang_web_framework

#include <fastcgi.h>
#include <fcgi_stdio.h>

void c_fcgi_write_stdout(const char* message, size_t length) {
	FCGI_fwrite((char*) message, length, 1, FCGI_stdout);
}

void c_fcgi_write_stderr(const char* message, size_t length) {
	FCGI_fwrite((char*) message, length, 1, FCGI_stderr);
}

int c_fcgi_init() {
	return FCGX_Init();
}

int c_fcgi_accept() {
	return FCGI_Accept();
}

void c_fcgi_printf(const char* message) {
	FCGI_printf((char*) message);
}

void c_fcgi_puts(const char* message) {
	FCGI_puts((char*) message);
}

void c_fcgi_get_stdin(char* buffer, size_t len) {
	size_t i;
	for(i=0; i<len; i++) {
		buffer[i] = FCGI_getchar();
	}
}
