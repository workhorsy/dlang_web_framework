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
	# Build client side code into wasm
	ldc2 -mtriple=wasm32-unknown-unknown-wasm -betterC wasm/wasm.d

	# Build server side code for fastcgi
	gcc -g -c -Wall -Werror source/fcgi.c -o fcgi.o -lfcgi
	ar rcs clibs.a fcgi.o
	$DC -g -w -of app.fcgi source/*.d -L clibs.a -L-lfcgi

	# Run the fastcgi server in nginx
	chmod +x app.fcgi
	spawn-fcgi -p 8000 -n app.fcgi
	set +x
}

small() {
	set -x
	gcc -os -c -Wall -Werror source/fcgi.c -o fcgi.o -lfcgi
	ar rcs clibs.a fcgi.o
	$DC -Oz -w -of app.fcgi source/*.d -L clibs.a -L-lfcgi
	strip -s app.fcgi
	chmod +x app.fcgi
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
