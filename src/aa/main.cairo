use starknet::get_execution_info;
use debug::PrintTrait;


//https://docs.starknet.io/documentation/architecture_and_concepts/Contracts/system-calls-cairo1/
fn fib(a: felt252, b: felt252, n: felt252) -> felt252 {
    let num: felt252 = 3;
    num.print();

    match gas::withdraw_gas_all(get_builtin_costs()) {
        Option::Some(_) => {},
        Option::None(_) => {
            let mut err_data = array::array_new();
            array::array_append(ref err_data, 'Out of gas');
            panic(err_data);
        },
    }

    match n {
        0 => a,
        _ => fib(b, a + b, n - 1),
    }
}
