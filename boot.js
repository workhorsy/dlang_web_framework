// Copyright (c) 2022 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
// Licensed under the MIT License
// A Dlang web framework
// https://github.com/workhorsy/dlang_web_framework

let exports = {};
let _memory_offset = 0;
let _element_id = 0;
let _element_to_id = {};

const js_get_string = (pointer, length) => {
	let view = new Uint8Array(exports.memory.buffer, pointer, length);
	let string = new TextDecoder().decode(view);
	return string;
};

const js_string_2_wasm_string = (string) => {
	let bytes = new TextEncoder().encode(string);
	let buffer = new Uint8Array(exports.memory.buffer, _memory_offset, bytes.byteLength + 1);
	_memory_offset += bytes.byteLength + 1;
	buffer.set(bytes);
	return buffer;
};

const js_console_log = (pointer, length) => {
	let message = js_get_string(pointer, length);
	console.log(message);
};

const js_document_querySelector = (pointer, length) => {
	let query = js_get_string(pointer, length);

	let element = document.querySelector(query);
	if (element) {
		_element_id += 1;
		let id = _element_id;
		_element_to_id[id] = element;
		return id;
	}

	return -1;
};

const js_element_addEventListener = (id, event_name_pointer, event_name_length, function_name_pointer, function_name_length) => {
	let event_name = js_get_string(event_name_pointer, event_name_length);
	console.log("!!! event_name: ", event_name);

	let function_name = js_get_string(function_name_pointer, function_name_length);
	console.log("!!! function_name: ", function_name);

	var element = _element_to_id[id];
	element.addEventListener(event_name, eval(function_name));
};

const js_fetch = (id, uri_pointer, uri_length) => {
	let uri = js_get_string(uri_pointer, uri_length);
	//console.log("!!!! called js_fetch: ", id, " ", uri_pointer, " ", uri_length);
	//console.log("!!!! called js_fetch: ", uri);
	fetch(uri).then(response => {
		//console.log("!!!! js_fetch got response: ", response);
		return response.text();//json();
	}).then(text => {
		//console.log(uri);
		//console.log(text);
		let uri_buffer = js_string_2_wasm_string(uri);
		let text_buffer = js_string_2_wasm_string(text);
		//console.log(uri_buffer);
		//console.log(text_buffer);
		exports.fetch_cb(id, uri_buffer.byteOffset, uri_buffer.byteLength, text_buffer.byteOffset, text_buffer.byteLength);
		_memory_offset = 0;
	});
};

const import_object = {
	memory: new WebAssembly.Memory({ initial: 256, maximum: 256, shared: true }),
	env: {
		js_console_log,
		js_document_querySelector,
		js_element_addEventListener,
		js_fetch,
	},
};

function main(wasm_file) {
	fetch(wasm_file).then(response =>
		response.arrayBuffer()
	).then(bytes =>
		WebAssembly.instantiate(bytes, import_object)
	).then(result => {
		exports = result.instance.exports;
		exports.main();
	});
}