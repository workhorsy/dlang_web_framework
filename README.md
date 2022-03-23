# dlang_web_framework

# TODO:

* extract http to HttpServer
* add unit tests
* add client side D using wasm https://wiki.dlang.org/Generating_WebAssembly_with_LDC
* make it work with fastcgi and socket server
* sessions via shared memory

# setup fcgi on ubuntu:
```sh
sudo apt-get install lighttpd php5-cgi
sudo lighty-enable-mod fastcgi
sudo /etc/init.d/lighttpd force-reload
```

# change the port in /etc/lighttpd/lighttpd.conf :
```sh
server.port               = 90
```

# change /etc/lighttpd/conf-available/10-fastcgi.conf :
```sh
fastcgi.server = ( "/" =>
	((
		"max-procs" => 1,
		"bin-path" => "/home/matt/fastcgi/application",
		"socket" => "/tmp/application.socket",
		"check-local" => "disable",
		"max-request-size" => 100000
	))
)
```
