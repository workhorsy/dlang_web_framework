
// BetterC
extern(C):

char[1024] d_memory = 0;
size_t d_memory_len = 1024;

void console_log(const char* s, size_t len);

void d_memory_copy(string src) {
	foreach (i ; 0 .. src.length) {
		d_memory[i] = src[i];
	}
	d_memory_len = src.length;
}

double add(double a, double b) {
	d_memory_copy("!!! Called add from D!");
	console_log(d_memory.ptr, d_memory_len);
	return a + b;
}

void boom() {
	d_memory_copy("Called BOOM from D!!!!!!!!!!!!!!!!!!!");
	console_log(d_memory.ptr, d_memory_len);
}

// Wasm entry point
void _start() {}

// FIXME: This is overridden so we don't get a bind error
void __assert(byte*, byte*, int) {
}
