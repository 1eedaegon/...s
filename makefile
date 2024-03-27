

.PHONY: install
install:
	go mod tidy

.PHONY: test
test: 
	go test ./... 

.PHONY: build
build:
	go build -o ./bin/3dots ./cmd/main.go


.PHONY: run-help
run-help: build
	./bin/3dots help

.PHONY: run
run: build
	./bin/3dots

.PHONY: debug-test
debug-test: 
	cd ./internal/server && go test -v -debug=true
