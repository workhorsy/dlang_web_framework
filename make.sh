#!/bin/bash
set -e
set +x


# Get the architecture
ARCH=`uname -m`
ARCH=${ARCH,,}
if [[ "$ARCH" == "x86_64" ]] || [[ "$ARCH" == "amd64" ]]; then
	ARCH='x86_64'
else
	echo "Unsupported architecture: $ARCH"
	exit
fi

# Get the OS
if [[ "$OSTYPE" == "linux"* ]]; then
	OS="linux"
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
	OS="windows"
else
	echo "Unknown OS: $OSTYPE"
	exit
fi

source ~/dlang/ldc-1.28.1/activate

# Get settings for this OS
if [[ "$OS" == "linux" ]]; then
	EXE_EXT=""
	OBJ_EXT=".o"
	LIB_EXT=".a"
	LIB_PREFIX="lib"
	DC="ldc2"
elif [[ "$OS" == "windows" ]]; then
	EXE_EXT=".exe"
	OBJ_EXT=".obj"
	LIB_EXT=".lib"
	LIB_PREFIX=""
	DC="ldc2"
fi

clean() {
	set -x
	rm -f *.a
	rm -f *.o
	rm -f *.fcgi
	rm -f *.wasm
	set +x
}

run() {
	set -x
	rm -f -rf build

	# Build client side code into wasm
	$DC -g -w -mtriple=wasm32-unknown-unknown-wasm -L-allow-undefined -betterC wasm/*.d -of build/wasm.wasm

	# Build server side code for fastcgi
	gcc -g -c -Wall -Werror source/fcgi.c -lfcgi -o build/fcgi.o
	ar rcs build/clibs.a build/fcgi.o
	$DC -g -w source/*.d -L build/clibs.a -L-lfcgi -of build/app.fcgi
	#strip -s build/app.fcgi

	# Move client and server code into root
	mv build/app.fcgi app.fcgi
	mv build/wasm.wasm wasm.wasm
	chmod +x app.fcgi

	# Run the fastcgi server in nginx
	spawn-fcgi -p 8000 -n app.fcgi
	set +x
}

if [[ "$1" == "run" ]]; then
	run
elif [[ "$1" == "clean" ]]; then
	clean
else
	echo "./make.sh run"
	echo "./make.sh clean"
fi
