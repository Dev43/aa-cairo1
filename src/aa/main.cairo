use starknet::get_execution_info;
use debug::PrintTrait;


#[account_contract]
mod Account {
    use array::SpanTrait;
    use array::ArrayTrait;
    use option::OptionTrait;
    use serde::Serde;
    use box::BoxTrait;
    use ecdsa::check_ecdsa_signature;
    use starknet::contract_address::ContractAddressPartialEq;
    use starknet::ContractAddress;
    use starknet::contract_address::ContractAddressSerde;

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


    struct Storage {
        public_key: felt252, 
    }

    #[constructor]
    fn constructor(_public_key: felt252) {
        public_key::write(_public_key);
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
        public_key::write(new_public_key);
    }

    #[view]
    fn get_public_key() -> felt252 {
        public_key::read()
    }

    #[view]
    fn is_valid_signature(message: felt252, sig_r: felt252, sig_s: felt252) -> bool {
        let _public_key: felt252 = public_key::read();
        check_ecdsa_signature(message, _public_key, sig_r, sig_s)
    }

    // Internals
    fn assert_only_self() {
        let caller = get_caller_address();
        let self = get_contract_address();
        assert(self == caller, 'Account: unauthorized.');
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
}
//https://docs.starknet.io/documentation/architecture_and_concepts/Contracts/system-calls-cairo1/

// create an AA wallet that allows anyone to use the funds in the contract.Bye

// they have a sort of session key - only can spend so much in x amount of time.Bye

// every action they do can only be going from the contract - to designated contracts (aave etc).


