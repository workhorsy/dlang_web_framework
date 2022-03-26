
// BetterC
extern(C):


void* memset(void* ptr, int value, size_t num) {
	auto ptr_ubyte = cast(ubyte*) ptr;
	auto value_ubyte = cast(ubyte) value;
	foreach (size_t i ; 0 .. num) {
		ptr_ubyte[i] = value_ubyte;
	}
	return ptr;
}

void* memcpy(void* ptr, const void* src, size_t num) {
	auto ptr_ubyte = cast(ubyte*) ptr;
	auto src_ubyte = cast(ubyte*) src;
	foreach (size_t i ; 0 .. num) {
		ptr_ubyte[i] = src_ubyte[i];
	}
	return ptr;
}

void _d_array_slice_copy(void* dst, size_t dstlen, void* src, size_t srclen, size_t elemsz) {
	import ldc.intrinsics : llvm_memcpy;
	llvm_memcpy!size_t(dst, src, dstlen * elemsz, 0);
}

char[1024] d_memory1 = 0;
char[1024] d_memory2 = 0;
size_t d_memory1_len = 1024;
size_t d_memory2_len = 1024;

void js_console_log(const char* s, size_t len);
size_t js_document_querySelector(const char* s, size_t len);
void js_element_addEventListener(long id, char* event_name, size_t event_name_len, char* function_name, size_t function_name_len);



HtmlElement querySelector(string query) {
	d_memory_copy(query, d_memory1, d_memory1_len);
	long id = js_document_querySelector(d_memory1.ptr, d_memory1_len);
	if (id != -1) {
		HtmlElement element = HtmlElement(id);
		return element;
	} else {
		return HtmlElement.init;
	}
}

struct HtmlElement {
	long id;

	void addEventListener(string event_name, string function_name) {
		d_memory_copy(event_name, d_memory1, d_memory1_len);
		d_memory_copy(function_name, d_memory2, d_memory2_len);
		js_element_addEventListener(id, d_memory1.ptr, d_memory1_len, d_memory2.ptr, d_memory2_len);
	}
}

void d_memory_copy(string src, out char[1024] d_memory, out size_t d_memory_len) {
	foreach (i ; 0 .. src.length) {
		d_memory[i] = src[i];
	}
	d_memory_len = src.length;
}

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

// Wasm entry point
void _start() {}

// FIXME: This is overridden so we don't get a bind error
void __assert(byte*, byte*, int) {
}
