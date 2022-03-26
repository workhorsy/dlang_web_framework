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

void main() {
	auto go = document.querySelector("#go");
	go.addEventListener("click", "exports.boom");

	auto add = document.querySelector("#add");
	add.addEventListener("click", "on_add");
}
