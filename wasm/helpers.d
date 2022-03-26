// Copyright (c) 2022 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
// Licensed under the MIT License
// A Dlang web framework
// https://github.com/workhorsy/dlang_web_framework

version (WebAssembly) {
} else {
	static assert(0, "This module should only be used with WebAssembly.");
}

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

void d_memory_copy(string src, out char[1024] d_memory, out size_t d_memory_len) {
	foreach (i ; 0 .. src.length) {
		d_memory[i] = src[i];
	}
	d_memory_len = src.length;
}

// Wasm entry point
void _start() {}

// FIXME: This is overridden so we don't get a bind error
void __assert(byte*, byte*, int) {
}
