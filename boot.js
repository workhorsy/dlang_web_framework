// Copyright (c) 2022 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
// Licensed under the MIT License
// A Dlang web framework
// https://github.com/workhorsy/dlang_web_framework

let exports = {};
let _element_id = 0;
let _element_to_id = {};

class MemoryManager {
	constructor() {
		this._memory_offset = 0;
		this.memory = new WebAssembly.Memory({ initial: 256, maximum: 256, shared: true });
	}

	pointer_to_string(pointer, length) {
		let view = new Uint8Array(exports.memory.buffer, pointer, length);
		let string = new TextDecoder().decode(view);
		return string;
	}

	string_to_buffer(string) {
		let bytes = new TextEncoder().encode(string);
		let buffer = new Uint8Array(exports.memory.buffer, this._memory_offset, bytes.byteLength + 1);
		this._memory_offset += bytes.byteLength + 1;
		buffer.set(bytes);
		return buffer;
	}

	free() {
		this._memory_offset = 0;
	}
}

class BindableProxy {
	constructor(data) {
		this.bindings = [];

		let container_bindable = this;
		let proxy = new Proxy(data, {
			set(obj, prop, value) {
					obj[prop] = value;
					console.log("!!!: ", obj, " ", proxy, " ", prop, " ", value);
					container_bindable.update(prop, value);

				return true;
			}
		});
		this.data = proxy;
	}

	bind(property, element, attribute, event_names) {
		// Added update event listeners for each event name
		if (event_names) {
			for (let name of event_names) {
				element.addEventListener(name, (e) => {
					this.data[property] = element[attribute];
				});
			}
		}

		// Add the binding to the list of bindings
		this.bindings.push({
			property: property,
			element: element,
			attribute: attribute,
			event_names: event_names,
		});

		// Update initial value from data
		element[attribute] = this.data[property];

		return this;
	}

	update(property, new_value) {
		// Update all other matching elements with new data
		for (const binding of this.bindings) {
			if (property == binding.property && binding.element != this) {
				console.log("    Updating: ", binding);
				binding.element[binding.attribute] = new_value;
			}
		}
	}
}

const mm = new MemoryManager();

const js_console_log = (pointer, length) => {
	let message = mm.pointer_to_string(pointer, length);
	console.log(message);
};

const js_document_querySelector = (pointer, length) => {
	let query = mm.pointer_to_string(pointer, length);

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
	let event_name = mm.pointer_to_string(event_name_pointer, event_name_length);
	console.log("!!! event_name: ", event_name);

	let function_name = mm.pointer_to_string(function_name_pointer, function_name_length);
	console.log("!!! function_name: ", function_name);

	var element = _element_to_id[id];
	element.addEventListener(event_name, eval(function_name));
};

const js_fetch = (id, uri_pointer, uri_length) => {
	let uri = mm.pointer_to_string(uri_pointer, uri_length);
	//console.log("!!!! called js_fetch: ", id, " ", uri_pointer, " ", uri_length);
	//console.log("!!!! called js_fetch: ", uri);
	fetch(uri).then(response => {
		//console.log("!!!! js_fetch got response: ", response);
		return response.text();//json();
	}).then(text => {
		//console.log(uri);
		//console.log(text);
		let uri_buffer = mm.string_to_buffer(uri);
		let text_buffer = mm.string_to_buffer(text);
		//console.log(uri_buffer);
		//console.log(text_buffer);
		exports.fetch_cb(id, uri_buffer.byteOffset, uri_buffer.byteLength, text_buffer.byteOffset, text_buffer.byteLength);
		mm.free();
	});
};

const import_object = {
	memory: mm.memory,
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
