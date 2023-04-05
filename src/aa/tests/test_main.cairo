use aa::main::Account;

#[test]
#[available_gas(2000000)]
fn test_account_gets_created() {
    let account = Account::constructor(1);
    assert(Account::get_public_key() == 1, 'account public key is invalid');
}


#[test]
#[available_gas(2000000)]
fn test_valid_signature() {
    let account = Account::constructor(
        0x7b7454acbe7845da996377f85eb0892044d75ae95d04d3325a391951f35d2ec
    );
    let message_hash = 0x503f4bea29baee10b22a7f10bdc82dda071c977c1f25b8f3973d34e6b03b2c;
    let signature_r = 0xbe96d72eb4f94078192c2e84d5230cde2a70f4b45c8797e2c907acff5060bb;
    let signature_s = 0x677ae6bba6daf00d2631fab14c8acf24be6579f9d9e98f67aa7f2770e57a1f5;
    assert(
        Account::is_valid_signature(message_hash, signature_r, signature_s),
        'signature returned false'
    );
}
