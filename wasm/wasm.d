
// BetterC
extern(C):

import helpers;
import html;

double add(double a, double b) {
	d_memory_copy("!!! Called add from D!", _arg1.memory, _arg1.len);
	js_console_log(_arg1.memory.ptr, _arg1.len);
	return a + b;
}

void boom() {
	d_memory_copy("Called BOOM from D!!!!!!!!!!!!!!!!!!!", _arg1.memory, _arg1.len);
	js_console_log(_arg1.memory.ptr, _arg1.len);
}

void main() {
	auto go = querySelector("#go");
	go.addEventListener("click", "exports.boom");

	auto add = querySelector("#add");
	add.addEventListener("click", "on_add");
}
