
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

# Class hash 0x6d5204157330272b8ca49c04129904faee32bbcb8377929fe0091b986ceccce
starknet-declare:
	starknet declare --contract artifacts/aa.json --account version_11

# ERC20 class hash 0x44c30417065903eb845190f6a5f2357be46f67d936ce4db56c8af464abca750
starknet-declare-erc20:
	starknet declare --contract artifacts/erc20.json --account version_11

starknet-declare-simulate:
	starknet declare --contract artifacts/aa.json --account version_11 --simulate

starknet-deploy:
	starknet deploy --class_hash 0x6d5204157330272b8ca49c04129904faee32bbcb8377929fe0091b986ceccce --account version_11 --inputs 0x02ca167e5fdf96eac11dbc780b86f0a9764c8cf4aa81bebce0e69b0207a8a831 0x0

language-server:
	cargo build --bin cairo-language-server --release


# starknet-compile-deprecated Account.cairo     --output contract_compiled.json     --abi contract_abi.json --cairo_path ../cairo-lang/src/ --account_contract
# starknet declare --contract contract_compiled.json --account braavos --deprecated
# starknet deploy_account --account version_11


# starknet invoke --address 0x0254b2bbb31977f64b7793bc610f85696e55ec1a37b3cdb0bd0debe9970a3dca  --function initialize --input 0x44c30417065903eb845190f6a5f2357be46f67d936ce4db56c8af464abca750 0x6869 0x6869 0x989680 0x00  --account version_11

#                                                                                                                                                            erc20                                           transfer                                                   
# starknet invoke --address 0x0254b2bbb31977f64b7793bc610f85696e55ec1a37b3cdb0bd0debe9970a3dca  --function __execute__ --inputs 0x017f8fe92ce8008ab714501b05d87a850b3cdceaa6696cfc7a5a88275325dcb2 0x03179612d7132c8ed24ba0e286d60d398c4aa1c234eb2274ca1bba47718e9d31   0x053b6abf375e7a4222fb306541f0c08dc65e9b9c0b4334cd446a4cb32f8ad93b 0x0   --account version_11

# ERC20 address 0x017f8fe92ce8008ab714501b05d87a850b3cdceaa6696cfc7a5a88275325dcb2
# Main address 0x0254b2bbb31977f64b7793bc610f85696e55ec1a37b3cdb0bd0debe9970a3dca

# initialize 0x44c30417065903eb845190f6a5f2357be46f67d936ce4db56c8af464abca750 0x54455354 0x54455354 1000000
# register as participant 0x02ca167e5fdf96eac11dbc780b86f0a9764c8cf4aa81bebce0e69b0207a8a831
# enjoy