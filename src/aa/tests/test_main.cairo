use aa::main::Account;

#[test]
#[available_gas(2000000)]
fn test_account() {
    let account = Account::constructor(1);
    assert(Account::get_public_key() == 1, 'account public key is invalid');
}
