#[account_contract]
mod Account {
    use array::SpanTrait;
    use array::ArrayTrait;
    use option::OptionTrait;
    use dict::Felt252DictTrait;
    use debug::PrintTrait;
    use traits::Into;
    use traits::TryInto;
    use traits::PartialOrd;
    use box::BoxTrait;

    use integer::U256PartialOrd;
    use integer::u256;
    use integer::u128_try_from_felt252;
    use integer::u64_try_from_felt252;

    use array::array_append;
    use array::array_new;

    use dict::Felt252Dict;

    use serde::Serde;

    use ecdsa::check_ecdsa_signature;

    use starknet::contract_address::ContractAddressPartialEq;
    use starknet::ContractAddress;
    use starknet::contract_address::ContractAddressSerde;
    use starknet::contract_address::contract_address_to_felt252;
    use starknet::contract_address::contract_address_try_from_felt252;
    use starknet::class_hash::ClassHash;
    use starknet::class_hash::Felt252TryIntoClassHash;
    use starknet::syscalls::deploy_syscall;

    use starknet::get_block_info;
    use starknet::get_caller_address;
    use starknet::get_contract_address;
    use starknet::get_tx_info;

    use starknet::StorageAccess;
    use starknet::StorageBaseAddress;
    use starknet::SyscallResult;
    use starknet::storage_read_syscall;
    use starknet::storage_write_syscall;
    use starknet::storage_address_from_base_and_offset;


    #[event]
    fn token_deployed(token_address: ContractAddress) {}

    struct Storage {
        s_owner_public_key: felt252,
        s_participants: LegacyMap<ContractAddress, Participant>,
        s_contract_whitelist_map: LegacyMap<ContractAddress, bool>,
        s_erc20_address: ContractAddress,
        s_contract_balance: u256,
        s_is_test: bool,
    }

    #[constructor]
    fn constructor(_public_key: felt252, _is_test: bool, ) {
        s_owner_public_key::write(_public_key);
        s_is_test::write(true);
    }

    // first we need to deploy the class hash of the token
    #[external]
    fn initialize(
        _token_class: felt252,
        _name: felt252,
        _symbol: felt252,
        _initial_supply: u256,
    ) {
        let contract_address = get_contract_address();
        let mut constructor_calldata: Array<felt252> = ArrayTrait::new();
        constructor_calldata.append(_name);
        constructor_calldata.append(_symbol);
        constructor_calldata.append(_initial_supply.low.into());
        constructor_calldata.append(_initial_supply.high.into());
        // we mint the tokens to the contract
        constructor_calldata.append(contract_address_to_felt252(contract_address));
        let class_hash: ClassHash = _token_class.try_into().unwrap();
        let result = deploy_syscall(class_hash, 420, constructor_calldata.span(), true);
        let (token_address, _) = result.unwrap_syscall();
        s_erc20_address::write(token_address);
        s_contract_balance::write(u256 { low: _initial_supply.low, high: _initial_supply.high });
        token_deployed(token_address);
    }


    #[external]
    fn contract_address() -> ContractAddress {
        get_contract_address()
    }

    #[external]
    fn add_to_contract_whitelist(contract_address: ContractAddress) -> bool {
        assert_only_owner();
        s_contract_whitelist_map::write(contract_address, true);
        true
    }

    #[external]
    fn remove_from_contract_whitelist(contract_address: ContractAddress) -> bool {
        assert_only_owner();
        s_contract_whitelist_map::write(contract_address, false);
        true
    }


    #[external]
    fn register_participant() {
        let participant_address = get_caller_address();
        let p = s_participants::read(participant_address);
        assert(p.public_key == 0, 'already registered');
        // TODO assign some tokens to this person
        let s_contract_balance = s_contract_balance::read();
        // only here to be able to run cairo tests, this would not be in production
        if (!s_is_test::read()) {
            assert(s_contract_balance > u256 { low: 1000_u128, high: 0_u128 }, 'no more tokens');
        }
        s_participants::write(
            participant_address,
            Participant {
                public_key: contract_address_to_felt252(participant_address), nonce: u256 {
                    low: 0_u128, high: 0_u128
                    }, balance: u256 {
                    low: 1000_u128, high: 0_u128
                }, timeout: get_block_info().unbox().block_timestamp + 10000_u64,
            }
        );
        // only here to be able to run cairo tests, this would not be in production
        if (!s_is_test::read()) {
            s_contract_balance::write(s_contract_balance - u256 { low: 1000_u128, high: 0_u128 });
        }
    }


    #[external]
    fn __execute__(mut calls: Array::<AccountCall>) -> Array::<Array::<felt252>> {
        assert_valid_transaction();
        let public_key = contract_address_to_felt252(get_caller_address());

        if !is_owner(
            public_key
        ) {
            let token = IERC20Dispatcher { contract_address: s_erc20_address::read() };
            let balance = token.balance_of(get_contract_address());
            let p = s_participants::read(get_caller_address());
            let participant_balance = p.balance;
            let mut res = ArrayTrait::new();
            let response = _execute_calls(calls, res);

            let new_balance = token.balance_of(get_contract_address());
            // this could be positive (gains) or negative (losses).
            let spent = balance - new_balance;
            assert(spent >= participant_balance, 'drew too much');

            s_participants::write(
                get_caller_address(),
                Participant {
                    public_key: contract_address_to_felt252(get_caller_address()),
                    nonce: p.nonce + u256 {
                        low: 1_u128, high: 0_u128
                    }, balance: participant_balance - spent, timeout: p.timeout,
                }
            );
            return response;
        } else {
            let mut res = ArrayTrait::new();
            _execute_calls(calls, res)
        }
    }


    fn _execute_calls(
        mut calls: Array<AccountCall>, mut res: Array::<Array::<felt252>>
    ) -> Array::<Array::<felt252>> {
        match gas::withdraw_gas() {
            Option::Some(_) => {},
            Option::None(_) => {
                let mut data = ArrayTrait::new();
                data.append('Out of gas');
                panic(data)
            },
        }
        match calls.pop_front() {
            Option::Some(call) => {
                let mut _res = _call_contract(call);
                let new_res: Array<felt252> = convert_span_to_array(ref _res);
                res.append(new_res);
                return res;
                // cannot have more than 1 call as we will reach a recursion error
                // return _execute_calls(calls, res);
            },
            Option::None(_) => {
                return res;
            },
        }
    }

    fn convert_span_to_array<T, impl TSerde: Serde::<T>, impl TDrop: Drop::<T>>(
        ref serialized: Span<felt252>
    ) -> Array<T> {
        let mut arr = ArrayTrait::new();
        arr.append(TSerde::deserialize(ref serialized).unwrap());
        arr
    }

    #[external]
    fn __validate__(calls: Array::<AccountCall>) {
        assert_valid_transaction()
    }

    #[external]
    fn __validate_declare__(class_hash: felt252) {
        assert_valid_transaction()
    }

    #[external]
    fn __validate_deploy__(
        class_hash: felt252, contract_address_salt: felt252, _public_key: felt252
    ) {
        assert_valid_transaction()
    }

    #[external]
    fn set_public_key(new_public_key: felt252) {
        assert_only_self();
        s_owner_public_key::write(new_public_key);
    }

    #[view]
    fn get_public_key() -> felt252 {
        s_owner_public_key::read()
    }

    #[view]
    fn balance() -> u256 {
        s_contract_balance::read()
    }

    #[view]
    fn is_valid_signature(
        message: felt252, public_key: felt252, sig_r: felt252, sig_s: felt252
    ) -> bool {
        check_ecdsa_signature(message, public_key, sig_r, sig_s)
    }

    #[view]
    fn participants(public_key: felt252) -> Participant {
        s_participants::read(contract_address_try_from_felt252(public_key).unwrap())
    }

    // Internals
    fn assert_only_owner() {
        let caller = get_caller_address();
        let self = s_owner_public_key::read();
        assert(contract_address_try_from_felt252(self).unwrap() == caller, 'only owner');
    }

    fn assert_only_self() {
        let caller = get_caller_address();
        let self = get_contract_address();
        assert(caller == self, 'only account.');
    }

    fn is_whitelisted(contract_address: ContractAddress) -> bool {
        s_contract_whitelist_map::read(contract_address)
    }

    fn assert_valid_transaction() {
        let tx_info = get_tx_info().unbox();
        let tx_hash = tx_info.transaction_hash;
        let signature = tx_info.signature;

        let caller = get_caller_address();

        // here we check if the caller is the owner of the contract. If not, we check if the caller is a participant
        let mut public_key = s_owner_public_key::read();

        if !is_owner(
            public_key
        ) {
            let p = s_participants::read(caller);
            // we ensure this user is registered
            assert(p.public_key != 0, 'not registered');
            // TODO time limit
            // assert(p.timeout != 0, 'timedout');
            public_key = p.public_key;
        }

        assert(signature.len() == 2_u32, 'bad signature length');

        let is_valid = is_valid_signature(
            tx_hash, public_key, *signature.at(0_u32), *signature.at(1_u32)
        );

        assert(is_valid, 'Invalid signature.');
    }

    fn _call_contract(call: AccountCall) -> Span::<felt252> {
        assert(is_whitelisted(call.to), 'contract not whitelisted');
        starknet::call_contract_syscall(
            call.to, call.selector, call.calldata.span()
        ).unwrap_syscall()
    }

    fn is_owner(public_key: felt252) -> bool {
        let owner = s_owner_public_key::read();
        return owner == public_key;
    }


    // types
    #[abi]
    trait IERC20 {
        #[view]
        fn balance_of(account: ContractAddress) -> u256;
        #[view]
        fn allowance(owner: ContractAddress, spender: ContractAddress) -> u256;
        #[external]
        fn mint(recipient: ContractAddress, amount: u256);
        #[external]
        fn transfer(recipient: ContractAddress, amount: u256) -> bool;
        #[external]
        fn transfer_from(sender: ContractAddress, recipient: ContractAddress, amount: u256) -> bool;
        #[external]
        fn approve(spender: ContractAddress, amount: u256) -> bool;
    }


    #[derive(Drop)]
    struct AccountCall {
        to: ContractAddress,
        selector: felt252,
        public_key: felt252,
        calldata: Array::<felt252>,
    }


    impl AccountCallSerde of serde::Serde::<AccountCall> {
        fn serialize(ref serialized: Array<felt252>, input: AccountCall) {
            serde::Serde::serialize(ref serialized, input.to);
            serde::Serde::serialize(ref serialized, input.selector);
            serde::Serde::serialize(ref serialized, input.public_key);
            serde::Serde::serialize(ref serialized, input.calldata);
        }
        fn deserialize(ref serialized: Span<felt252>) -> Option<AccountCall> {
            Option::Some(
                AccountCall {
                    to: serde::Serde::<ContractAddress>::deserialize(ref serialized)?,
                    selector: serde::Serde::deserialize(ref serialized)?,
                    public_key: serde::Serde::deserialize(ref serialized)?,
                    calldata: serde::Serde::<Array::<felt252>>::deserialize(ref serialized)?,
                }
            )
        }
    }

    #[derive(Drop)]
    struct Participant {
        public_key: felt252,
        nonce: u256,
        balance: u256,
        timeout: u64,
    }

    impl ParticipantStorageAccess of StorageAccess::<Participant> {
        fn read(address_domain: u32, base: StorageBaseAddress) -> SyscallResult::<Participant> {
            Result::Ok(
                Participant {
                    public_key: storage_read_syscall(
                        address_domain, storage_address_from_base_and_offset(base, 0_u8)
                    )?,
                    nonce: u256 {
                        high: u128_try_from_felt252(
                            storage_read_syscall(
                                address_domain, storage_address_from_base_and_offset(base, 1_u8)
                            )?
                        ).unwrap(),
                        low: u128_try_from_felt252(
                            storage_read_syscall(
                                address_domain, storage_address_from_base_and_offset(base, 2_u8)
                            )?
                        ).unwrap(),
                        }, balance: u256 {
                        high: u128_try_from_felt252(
                            storage_read_syscall(
                                address_domain, storage_address_from_base_and_offset(base, 3_u8)
                            )?
                        ).unwrap(),
                        low: u128_try_from_felt252(
                            storage_read_syscall(
                                address_domain, storage_address_from_base_and_offset(base, 4_u8)
                            )?
                        ).unwrap(),
                    },
                    timeout: u64_try_from_felt252(
                        storage_read_syscall(
                            address_domain, storage_address_from_base_and_offset(base, 5_u8)
                        )?
                    ).unwrap(),
                }
            )
        }

        fn write(
            address_domain: u32, base: StorageBaseAddress, value: Participant
        ) -> SyscallResult::<()> {
            storage_write_syscall(
                address_domain, storage_address_from_base_and_offset(base, 0_u8), value.public_key
            );
            storage_write_syscall(
                address_domain,
                storage_address_from_base_and_offset(base, 1_u8),
                value.nonce.high.into()
            );
            storage_write_syscall(
                address_domain,
                storage_address_from_base_and_offset(base, 2_u8),
                value.nonce.low.into()
            );
            storage_write_syscall(
                address_domain,
                storage_address_from_base_and_offset(base, 3_u8),
                value.balance.high.into()
            );
            storage_write_syscall(
                address_domain,
                storage_address_from_base_and_offset(base, 4_u8),
                value.balance.low.into()
            );
            storage_write_syscall(
                address_domain,
                storage_address_from_base_and_offset(base, 5_u8),
                value.timeout.into()
            )
        }
    }

    impl ParticipantSerde of serde::Serde::<Participant> {
        fn serialize(ref serialized: Array<felt252>, input: Participant) {
            serde::Serde::serialize(ref serialized, input.public_key);
            serde::Serde::serialize(ref serialized, input.nonce);
            serde::Serde::serialize(ref serialized, input.balance);
            serde::Serde::serialize(ref serialized, input.timeout);
        }
        fn deserialize(ref serialized: Span<felt252>) -> Option<Participant> {
            Option::Some(
                Participant {
                    public_key: serde::Serde::<felt252>::deserialize(ref serialized)?,
                    nonce: serde::Serde::<u256>::deserialize(ref serialized)?,
                    balance: serde::Serde::<u256>::deserialize(ref serialized)?,
                    timeout: serde::Serde::<u64>::deserialize(ref serialized)?,
                }
            )
        }
    }
}

