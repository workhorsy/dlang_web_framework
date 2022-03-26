
// BetterC
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
	auto go = querySelector("#go");
	go.addEventListener("click", "exports.boom");

	auto add = querySelector("#add");
	add.addEventListener("click", "on_add");
}
