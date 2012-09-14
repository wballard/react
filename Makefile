TOP=$(dir $(realpath $(lastword $(MAKEFILE_LIST))))
XPATH=$(TOP)node_modules/.bin:`pwd`/node_modules/.bin:$(PATH)
.PHONY: test


all: react.min.js

react.min.js: react.js
	export PATH=$(XPATH); \
	cat $^ \
	| uglifyjs \
	> $@

react.js: src/watch.js src/proxy.coffee
	cat src/watch.js > $@
	export PATH=$(XPATH); coffee --print --join $^ \
	>> $@

test:
	export PATH=$(XPATH); mocha --compilers coffee:coffee-script

watch:
	export PATH=$(XPATH); mocha --compilers coffee:coffee-script --watch
