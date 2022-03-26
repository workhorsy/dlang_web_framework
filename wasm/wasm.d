
// BetterC
extern(C):

char[1024] d_memory1 = 0;
char[1024] d_memory2 = 0;
size_t d_memory1_len = 1024;
size_t d_memory2_len = 1024;

void js_console_log(const char* s, size_t len);
size_t js_document_querySelector(const char* s, size_t len);
void js_element_addEventListener(long id, char* event_name, size_t event_name_len, char* function_name, size_t function_name_len);

HtmlElement querySelector(string query) {
	d_memory_copy1(query);
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
		d_memory_copy1(event_name);
		d_memory_copy2(function_name);
		js_element_addEventListener(id, d_memory1.ptr, d_memory1_len, d_memory2.ptr, d_memory2_len);
	}
}

void d_memory_copy1(string src) {
	foreach (i ; 0 .. src.length) {
		d_memory1[i] = src[i];
	}
	d_memory1_len = src.length;
}

void d_memory_copy2(string src) {
	foreach (i ; 0 .. src.length) {
		d_memory2[i] = src[i];
	}
	d_memory2_len = src.length;
}

double add(double a, double b) {
	d_memory_copy1("!!! Called add from D!");
	js_console_log(d_memory1.ptr, d_memory1_len);
	return a + b;
}

void boom() {
	d_memory_copy1("Called BOOM from D!!!!!!!!!!!!!!!!!!!");
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
