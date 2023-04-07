#[account_contract]
mod Account {
    use array::SpanTrait;
    use array::ArrayTrait;
    use option::OptionTrait;
    use dict::Felt252DictTrait;
    use debug::PrintTrait;
    use traits::PartialOrd;
    use integer::U256PartialOrd;
    use integer::u256;
    use integer::u128_try_from_felt252;

    use dict::Felt252Dict;
    use serde::Serde;
    use box::BoxTrait;
    use ecdsa::check_ecdsa_signature;
    use starknet::contract_address::ContractAddressPartialEq;
    use starknet::ContractAddress;
    use starknet::contract_address::ContractAddressSerde;
    use starknet::contract_address::contract_address_to_felt252;
    use starknet::contract_address::contract_address_try_from_felt252;

    use traits::Into;
    use traits::TryInto;
    use starknet::StorageAccess;
    use starknet::StorageBaseAddress;
    use starknet::SyscallResult;
    use starknet::storage_read_syscall;
    use starknet::storage_write_syscall;
    use starknet::storage_address_from_base_and_offset;
    use starknet::get_caller_address;
    use starknet::get_contract_address;
    use starknet::get_tx_info;

    #[derive(Drop)]
    struct AccountCall {
        to: ContractAddress,
        selector: felt252,
        calldata: Array::<felt252>
    }


    impl AccountCallSerde of serde::Serde::<AccountCall> {
        fn serialize(ref serialized: Array<felt252>, input: AccountCall) {
            serde::Serde::serialize(ref serialized, input.to);
            serde::Serde::serialize(ref serialized, input.selector);
            serde::Serde::serialize(ref serialized, input.calldata);
        }
        fn deserialize(ref serialized: Span<felt252>) -> Option<AccountCall> {
            Option::Some(
                AccountCall {
                    to: serde::Serde::<ContractAddress>::deserialize(ref serialized)?,
                    selector: serde::Serde::deserialize(ref serialized)?,
                    calldata: serde::Serde::<Array::<felt252>>::deserialize(ref serialized)?,
                }
            )
        }
    }

    #[derive(Drop, Serde)]
    struct Participant {
        public_key: felt252,
        nonce: u128,
        balance: u128
    }

    impl ParticipantStorageAccess of StorageAccess::<Participant> {
        fn read(address_domain: u32, base: StorageBaseAddress) -> SyscallResult::<Participant> {
            Result::Ok(
                Participant {
                    public_key: storage_read_syscall(
                        address_domain, storage_address_from_base_and_offset(base, 0_u8)
                    )?,
                    nonce: u128_try_from_felt252(
                        storage_read_syscall(
                            address_domain, storage_address_from_base_and_offset(base, 1_u8)
                        )?
                    ).unwrap(),
                    balance: u128_try_from_felt252(
                        storage_read_syscall(
                            address_domain, storage_address_from_base_and_offset(base, 2_u8)
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
                address_domain, storage_address_from_base_and_offset(base, 1_u8), value.nonce.into()
            );
            storage_write_syscall(
                address_domain,
                storage_address_from_base_and_offset(base, 2_u8),
                value.balance.into()
            )
        }
    }

    impl ParticipantSerde of serde::Serde::<Participant> {
        fn serialize(ref serialized: Array<felt252>, input: Participant) {
            serde::Serde::serialize(ref serialized, input.public_key);
            serde::Serde::serialize(ref serialized, input.nonce);
            serde::Serde::serialize(ref serialized, input.balance);
        }
        fn deserialize(ref serialized: Span<felt252>) -> Option<Participant> {
            Option::Some(
                Participant {
                    public_key: serde::Serde::<felt252>::deserialize(ref serialized)?,
                    nonce: serde::Serde::<u128>::deserialize(ref serialized)?,
                    balance: serde::Serde::<u128>::deserialize(ref serialized)?,
                }
            )
        }
    }


    // setup proxying
    // see how to deploy the ERC20 and the contract (or change owner)
    // example transaction that does trading

    struct Storage {
        s_public_key: felt252,
        // s_erc20_address: felt252,
        // public_key, nonce and balance like this for now
        // as I don't have docs for the StorageAccess 
        s_participants: LegacyMap<ContractAddress, Participant>,
        s_contract_whitelist_map: LegacyMap<ContractAddress, bool>,
        contract_balance: u256,
    }

    #[constructor]
    fn constructor(_public_key: felt252) {
        s_public_key::write(_public_key);
        // s_erc20_address::write(_erc20_address);
        // we mint a balance of 10 million tokens to the contract
        contract_balance::write(u256 { low: 10000000_u128, high: 0_u128 });
    }

    #[external]
    fn contract_address() -> ContractAddress {
        get_contract_address()
    }

    #[external]
    fn add_to_contract_whitelist(contract_address: ContractAddress) -> bool {
        assert_only_self();
        s_contract_whitelist_map::write(contract_address, true);
        true
    }

    #[external]
    fn remove_from_contract_whitelist(contract_address: ContractAddress) -> bool {
        assert_only_self();
        s_contract_whitelist_map::write(contract_address, false);
        true
    }


    #[external]
    fn register_participant() {
        let participant_address = get_caller_address();
        let p = s_participants::read(participant_address);
        assert(p.public_key == 0, 'already registered');
        // first we check if the current balance in the contract has enough tokens to give our user 1000 tokens
        let contract_balance = contract_balance::read();
        assert(contract_balance > u256 { low: 1000_u128, high: 0_u128 }, 'no more tokens');
        // s_balance_map::write(participant_address, u256 { low: 10000000_u128, high: 0_u128 });
        // // we set nonce to 0
        // s_nonce_map::write(participant_address, u256 { low: 0_u128, high: 0_u128 });
        s_participants::write(
            participant_address,
            Participant {
                public_key: contract_address_to_felt252(participant_address),
                nonce: 0_u128,
                balance: 1000_u128
            }
        );
        contract_balance::write(contract_balance - u256 { low: 1000_u128, high: 0_u128 });
    }


    #[external]
    fn __execute__(mut calls: Array::<AccountCall>) -> Array::<Array::<felt252>> {
        assert_valid_transaction();
        let mut res = ArrayTrait::new();
        _execute_calls(calls, res)
    }

    fn _execute_calls(
        mut calls: Array<AccountCall>, mut res: Array::<Array::<felt252>>
    ) -> Array::<Array::<felt252>> {
        match calls.pop_front() {
            Option::Some(call) => {
                let mut _res = _call_contract(call);
                let r = convert_span_to_array(_res);
                res.append(r);
                return _execute_calls(calls, res);
            },
            Option::None(_) => {
                return res;
            },
        }
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
        s_public_key::write(new_public_key);
    }

    #[view]
    fn get_public_key() -> felt252 {
        s_public_key::read()
    }

    #[view]
    fn balance() -> u256 {
        contract_balance::read()
    }

    #[view]
    fn is_valid_signature(message: felt252, sig_r: felt252, sig_s: felt252) -> bool {
        let _public_key: felt252 = s_public_key::read();
        check_ecdsa_signature(message, _public_key, sig_r, sig_s)
    }

    #[view]
    fn participants(public_key: felt252) -> Participant {
        s_participants::read(contract_address_try_from_felt252(public_key).unwrap())
    }

    // Internals
    fn assert_only_self() {
        let caller = get_caller_address();
        let self = get_contract_address();
        assert(self == caller, 'Account: unauthorized.');
    }

    fn is_whitelisted(contract_address: ContractAddress) -> bool {
        s_contract_whitelist_map::read(contract_address)
    }

    fn assert_valid_transaction() {
        let tx_info = get_tx_info().unbox();
        let tx_hash = tx_info.transaction_hash;
        let signature = tx_info.signature;

        assert(signature.len() == 2_u32, 'bad signature length');

        let is_valid = is_valid_signature(tx_hash, *signature.at(0_u32), *signature.at(1_u32));

        assert(is_valid, 'Invalid signature.');
    }

    fn _call_contract(call: AccountCall) -> Span::<felt252> {
        starknet::call_contract_syscall(
            call.to, call.selector, call.calldata.span()
        ).unwrap_syscall()
    }


    fn convert_span_to_array(mut span: Span<felt252>) -> Array<felt252> {
        let length = *span.pop_front().unwrap();
        let mut arr = ArrayTrait::new();
        deserialize_array(ref span, arr, length).unwrap()
    }

    // taken from the corelib
    fn deserialize_array<T, impl TSerde: Serde::<T>, impl TDrop: Drop::<T>>(
        ref serialized: Span<felt252>, mut curr_output: Array<T>, remaining: felt252
    ) -> Option<Array<T>> {
        match gas::withdraw_gas() {
            Option::Some(_) => {},
            Option::None(_) => {
                let mut data = ArrayTrait::new();
                data.append('Out of gas');
                panic(data);
            },
        }
        if remaining == 0 {
            return Option::Some(curr_output);
        }
        curr_output.append(TSerde::deserialize(ref serialized)?);
        deserialize_array(ref serialized, curr_output, remaining - 1)
    }
}

