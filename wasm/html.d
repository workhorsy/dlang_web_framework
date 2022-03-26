
// BetterC
extern(C):

// FIXME: Rename to _arg_string1 and _arg_string2
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
