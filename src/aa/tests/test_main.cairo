use aa::main::Account;
use aa::erc20::ERC20;
use debug::PrintTrait;
use starknet::contract_address_try_from_felt252;
use starknet::get_caller_address;
use starknet::get_contract_address;
use starknet::testing::set_caller_address;
use option::OptionTrait;

fn main_address() -> felt252 {
    0x7b7454acbe7845da996377f85eb0892044d75ae95d04d3325a391951f35d2ec
}

#[test]
#[available_gas(2000000)]
fn test_account_gets_created() {
    let account = Account::constructor(1);
    assert(Account::get_public_key() == 1, 'account public key is invalid');
}


#[test]
#[available_gas(2000000)]
fn test_valid_signature() {
    let account = Account::constructor(main_address());
    let message_hash = 0x503f4bea29baee10b22a7f10bdc82dda071c977c1f25b8f3973d34e6b03b2c;
    let signature_r = 0xbe96d72eb4f94078192c2e84d5230cde2a70f4b45c8797e2c907acff5060bb;
    let signature_s = 0x677ae6bba6daf00d2631fab14c8acf24be6579f9d9e98f67aa7f2770e57a1f5;
    assert(
        Account::is_valid_signature(message_hash, signature_r, signature_s),
        'signature returned false'
    );
}

#[test]
#[available_gas(2000000)]
fn test_erc20() {
    let erc20 = ERC20::constructor(
        'test',
        'TST',
        u256 { low: 1000000_u128, high: 0_u128 },
        contract_address_try_from_felt252(main_address()).unwrap()
    );
    assert(ERC20::name() == 'test', 'name is not the same');
}

#[test]
#[available_gas(2000000)]
fn test_participant_registration_and_access() {
    let account = Account::constructor(main_address());
    set_caller_address(contract_address_try_from_felt252(main_address()).unwrap());
    Account::register_participant();
    let participant = Account::participants(main_address());
    let contract_balance = Account::balance();
    assert(contract_balance == u256 { low: 9999000_u128, high: 0_u128 }, 'balance is wrong');
    assert(participant.balance == 1000_u128, 'participant balance is wrong');
    assert(participant.public_key != 0, 'participant is not registered');
}

