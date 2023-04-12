
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
	cargo run --bin cairo-test -- --starknet $(SOURCE_FOLDER)

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

# Class hash 0x2cb448f7d1098b6fcd800d54993cd1b786157b895cc0d3f79742a1ae7b4f68b
starknet-declare:
	starknet declare --contract artifacts/aa.json --account version_11

# ERC20 class hash 0x44c30417065903eb845190f6a5f2357be46f67d936ce4db56c8af464abca750
starknet-declare-erc20:
	starknet declare --contract artifacts/erc20.json --account version_11

starknet-declare-simulate:
	starknet declare --contract artifacts/aa.json --account version_11 --simulate

starknet-deploy:
	starknet deploy --class_hash 0x2cb448f7d1098b6fcd800d54993cd1b786157b895cc0d3f79742a1ae7b4f68b --account version_11 --inputs 0x02ca167e5fdf96eac11dbc780b86f0a9764c8cf4aa81bebce0e69b0207a8a831 0x0

language-server:
	cargo build --bin cairo-language-server --release


# starknet-compile-deprecated Account.cairo     --output contract_compiled.json     --abi contract_abi.json --cairo_path ../cairo-lang/src/ --account_contract
# starknet declare --contract contract_compiled.json --account braavos --deprecated
# starknet deploy_account --account version_11


# starknet invoke --address 0x00505fa45da5785842bf5052ef14371494bba1e6594f78ab4a3b537bef7edaa7  --function initialize --input 0x44c30417065903eb845190f6a5f2357be46f67d936ce4db56c8af464abca750 0x6869 0x6869 0x989680 0x00  --account version_11

#                                                                                                                                                            erc20                                           balance_of       calldata                                            
# starknet invoke --address 0x00505fa45da5785842bf5052ef14371494bba1e6594f78ab4a3b537bef7edaa7  --function __execute__ --input 0x01c19c07985736927f9696303febc24b239d34a90bef8f0f7b0041045129c58d 0x62616c616e63655f6f66            0x00505fa45da5785842bf5052ef14371494bba1e6594f78ab4a3b537bef7edaa7   --account version_11

# ERC20 address 0x01c19c07985736927f9696303febc24b239d34a90bef8f0f7b0041045129c58d
# Main address 0x00505fa45da5785842bf5052ef14371494bba1e6594f78ab4a3b537bef7edaa7

# initialize 0x44c30417065903eb845190f6a5f2357be46f67d936ce4db56c8af464abca750 0x54455354 0x54455354 1000000
# register as participant 0x02ca167e5fdf96eac11dbc780b86f0a9764c8cf4aa81bebce0e69b0207a8a831
# enjoy