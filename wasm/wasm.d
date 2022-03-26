
// BetterC
extern(C):

import helpers;
import html;

double add(double a, double b) {
	d_memory_copy("!!! Called add from D!", d_memory1, d_memory1_len);
	js_console_log(d_memory1.ptr, d_memory1_len);
	return a + b;
}

void boom() {
	d_memory_copy("Called BOOM from D!!!!!!!!!!!!!!!!!!!", d_memory1, d_memory1_len);
	js_console_log(d_memory1.ptr, d_memory1_len);
}

void main() {
	auto go = querySelector("#go");
	go.addEventListener("click", "exports.boom");

	auto add = querySelector("#add");
	add.addEventListener("click", "on_add");
}
