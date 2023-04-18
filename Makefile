
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

# Class hash 0x3181faa351e7cde09775ce591f59419e3b689e4c93018c7e6db4164cdc86f75
starknet-declare:
	starknet declare --contract artifacts/aa.json --account version_11

# ERC20 class hash 0x44c30417065903eb845190f6a5f2357be46f67d936ce4db56c8af464abca750
starknet-declare-erc20:
	starknet declare --contract artifacts/erc20.json --account version_11

starknet-declare-simulate:
	starknet declare --contract artifacts/aa.json --account version_11 --simulate

starknet-deploy:
	starknet deploy --class_hash 0x3181faa351e7cde09775ce591f59419e3b689e4c93018c7e6db4164cdc86f75 --account version_11 --inputs 0x02ca167e5fdf96eac11dbc780b86f0a9764c8cf4aa81bebce0e69b0207a8a831 0x0

language-server:
	cargo build --bin cairo-language-server --release


# ERC20 address 0x05136202f60fb30a34cd7c84d11c3c97ad1582bad66aeae9c9c0268ee2e2e4d1
# Main address 0x01d873aa14bf120d190cf9ca574cbc884cf2c5ba754b2352576943f2d700edd4

# starknet invoke --address 0x01d873aa14bf120d190cf9ca574cbc884cf2c5ba754b2352576943f2d700edd4  --function initialize --input 0x44c30417065903eb845190f6a5f2357be46f67d936ce4db56c8af464abca750 0x6869 0x6869 0x989680 0x00  --account version_11
# starknet invoke --address 0x01d873aa14bf120d190cf9ca574cbc884cf2c5ba754b2352576943f2d700edd4  --function __execute__ --inputs 0x05136202f60fb30a34cd7c84d11c3c97ad1582bad66aeae9c9c0268ee2e2e4d1 0x03179612d7132c8ed24ba0e286d60d398c4aa1c234eb2274ca1bba47718e9d31   0x053b6abf375e7a4222fb306541f0c08dc65e9b9c0b4334cd446a4cb32f8ad93b 0x0   --account version_11


# initialize 0x44c30417065903eb845190f6a5f2357be46f67d936ce4db56c8af464abca750 0x54455354 0x54455354 1000000
# register as participant 0x02ca167e5fdf96eac11dbc780b86f0a9764c8cf4aa81bebce0e69b0207a8a831
# enjoy

# balance_of
# starknet invoke --address 0x01d873aa14bf120d190cf9ca574cbc884cf2c5ba754b2352576943f2d700edd4  --function __execute__ --inputs 0x05136202f60fb30a34cd7c84d11c3c97ad1582bad66aeae9c9c0268ee2e2e4d1 0x035a73cd311a05d46deda634c5ee045db92f811b4e74bca4437fcb5302b7af33  0x053b6abf375e7a4222fb306541f0c08dc65e9b9c0b4334cd446a4cb32f8ad93b   --account version_11

# transfer
# starknet invoke --address 0x01d873aa14bf120d190cf9ca574cbc884cf2c5ba754b2352576943f2d700edd4  --function __execute__ --inputs 0x05136202f60fb30a34cd7c84d11c3c97ad1582bad66aeae9c9c0268ee2e2e4d1 0x83afd3f4caedc6eebf44246fe54e38c95e3179a5ec9ea81740eca5b482d12e  0x053b6abf375e7a4222fb306541f0c08dc65e9b9c0b4334cd446a4cb32f8ad93b,0x1,0x0   --account version_11
