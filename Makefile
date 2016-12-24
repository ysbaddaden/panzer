CRYSTAL_BIN ?= $(shell which crystal)

all: bin/panzer

basic: all bin/basic
	./bin/panzer "$(PWD)/bin/basic"

stubborn: all bin/stubborn
	./bin/panzer "$(PWD)/bin/stubborn"

http: all bin/http
	./bin/panzer "$(PWD)/bin/http"

bin/panzer: src/main.cr
	$(CRYSTAL_BIN) build -o bin/panzer src/main.cr

bin/basic: samples/basic.cr
	$(CRYSTAL_BIN) build -o bin/basic samples/basic.cr

bin/stubborn: samples/stubborn.cr
	$(CRYSTAL_BIN) build -o bin/stubborn samples/stubborn.cr

bin/http: samples/http.cr
	$(CRYSTAL_BIN) build -o bin/http --release samples/http.cr

clean:
	rm -f bin/panzer bin/basic bin/stubborn bin/http
