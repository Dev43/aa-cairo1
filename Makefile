
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

starknet-declare:
	starknet declare --contract artifacts/aa.json --account version_11

language-server:
	cargo build --bin cairo-language-server --release


# starknet-compile-deprecated Account.cairo     --output contract_compiled.json     --abi contract_abi.json --cairo_path ../cairo-lang/src/ --account_contract
# starknet declare --contract contract_compiled.json --account braavos --deprecated
# starknet deploy_account --account version_11