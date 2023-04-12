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
    let account = Account::constructor(1, true);
    assert(Account::get_public_key() == 1, 'account public key is invalid');
}


#[test]
#[available_gas(2000000)]
fn test_valid_signature() {
    let account = Account::constructor(1, true);
    // actual public key
    let public_key = 0x02ca167e5fdf96eac11dbc780b86f0a9764c8cf4aa81bebce0e69b0207a8a831;
    let message_hash = 0x002a0fdf856f7450f3f92b2d51175564296dcd23549f3c4f3e0af4f627babcd7;
    let signature_r = 0x62d4168a6e98c89d8b4f9ae9a659c9c94331a04491732c87048ffe1ac7f8f6f;
    let signature_s = 0x599c1e825bddbd84c94edbdc430f1478c094b4c48a8115f8f29da8abd7edd18;

    assert(
        Account::is_valid_signature(message_hash, public_key, signature_r, signature_s),
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
    let account = Account::constructor(main_address(), true);
    set_caller_address(contract_address_try_from_felt252(main_address()).unwrap());
    Account::register_participant();
    let participant = Account::participants(main_address());
    let contract_balance = Account::balance();
    // assert(contract_balance == u256 { low: 9999000_u128, high: 0_u128 }, 'balance is wrong');
    assert(
        participant.balance == u256 { low: 1000_u128, high: 0_u128 }, 'participant balance is wrong'
    );
    assert(participant.public_key != 0, 'participant is not registered');
}

