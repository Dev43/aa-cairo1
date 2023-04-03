use aa::main::fib;

#[test]
#[available_gas(2000000)]
fn test_fib() {
    let x = fib(0, 1, 13);
    assert(x == 233, 'fib(0, 1, 13) == 233');
}
