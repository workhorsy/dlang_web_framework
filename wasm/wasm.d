// Copyright (c) 2022 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
// Licensed under the MIT License
// A Dlang web framework
// https://github.com/workhorsy/dlang_web_framework

version (WebAssembly) {
} else {
	static assert(0, "This module should only be used with WebAssembly.");
}

extern(C):

import html;

double add(double a, double b) {
	console.log("!!! Called add from D!");
	return a + b;
}

void boom() {
	console.log("Called BOOM from D!!!!!!!!!!!!!!!!!!!");
}

void get_user() {
	console.log("Called get_user from D!!!!!!!!!!!!!!!!!!!");
	extern (C) void delegate(string) cb = (string text) {
		console.log("!!! Got user: ");
		console.log(text);
	};

	fetch("/user/99", cb);
}

void main() {
	auto go = document.querySelector("#go");
	go.addEventListener("click", "exports.boom");

	auto add = document.querySelector("#add");
	add.addEventListener("click", "on_add");

	auto get_user = document.querySelector("#get_user");
	get_user.addEventListener("click", "exports.get_user");
}
