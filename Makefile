
.SILENT:
.PHONY: compile
SOURCE_FOLDER=./src/aa

install:
	git submodule init && git submodule update 

update:
	git submodule update

build:
	cargo build

test:
	cargo run --bin cairo-test -- --starknet --path $(SOURCE_FOLDER)

format:
	cargo run --bin cairo-format -- --recursive $(SOURCE_FOLDER) --print-parsing-errors

check-format:
	cargo run --bin cairo-format -- --check --recursive $(SOURCE_FOLDER)

starknet-compile:
	mkdir -p artifacts && \
		cargo run --bin starknet-compile -- ${SOURCE_FOLDER}/main.cairo artifacts/$(shell basename $(SOURCE_FOLDER)).json --allowed-libfuncs-list-name experimental_v0.1.0

language-server:
	cargo build --bin cairo-language-server --release