
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
		cargo run --bin starknet-compile -- ${SOURCE_FOLDER}/main.cairo artifacts/$(shell basename $(SOURCE_FOLDER)).json --replace-ids --allowed-libfuncs-list-name experimental_v0.1.0 

starknet-compile-erc20:
	mkdir -p artifacts && \
		cargo run --bin starknet-compile -- ${SOURCE_FOLDER}/erc20.cairo artifacts/erc20.json --replace-ids --allowed-libfuncs-list-name experimental_v0.1.0 

# Class hash 0x1addca6547a8411a30458aaefd7c8b65a7b31d215303ab1e9aaa7f49fdf23ed
starknet-declare:
	starknet declare --contract artifacts/aa.json --account version_11

# ERC20 class hash 0x44c30417065903eb845190f6a5f2357be46f67d936ce4db56c8af464abca750
starknet-declare-erc20:
	starknet declare --contract artifacts/erc20.json --account version_11

starknet-declare-simulate:
	starknet declare --contract artifacts/aa.json --account version_11 --simulate

starknet-deploy:
	starknet deploy --class_hash 0x1addca6547a8411a30458aaefd7c8b65a7b31d215303ab1e9aaa7f49fdf23ed --account version_11 --inputs 0x30839370d535b1a1728ab77e834e50bb0c70625e25a092abea7f40d875148ec 0x1

language-server:
	cargo build --bin cairo-language-server --release


# starknet-compile-deprecated Account.cairo     --output contract_compiled.json     --abi contract_abi.json --cairo_path ../cairo-lang/src/ --account_contract
# starknet declare --contract contract_compiled.json --account braavos --deprecated
# starknet deploy_account --account version_11


# starknet invoke --address 0x018cfb1Bee4fCc534134dA86E8E6c04463964A2CCec781Ec2a94d8D37e26Ed31  --function initialize --input 0x44c30417065903eb845190f6a5f2357be46f67d936ce4db56c8af464abca750 0x6869 0x6869 0x989680 0x00  --account version_11
