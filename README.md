# dlang_web_framework

# TODO:

* pure D client side template, or template language? look at other frameworks.

* Make sending files not allocate
* Make sending files stream large files
* add unit tests
* make it work with fastcgi and socket server
* sessions via shared memory
* Recompile in browser via ldc built with wasm?

# Setup nginx with fcgi on ubuntu:
```sh
sudo apt-get install build-essential libfcgi-dev nginx spawn-fcgi
sudo service nginx start
```
# Setup nginx config
```sh
sudo mv /etc/nginx/nginx.conf /etc/nginx/old_nginx.conf.original
sudo ln -s `pwd`/nginx.conf /etc/nginx/nginx.conf
sudo service nginx force-reload
```

# Build app and run under fcgi:
```sh
./make.sh run
```
