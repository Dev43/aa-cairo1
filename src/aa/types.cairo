use array::SpanTrait;
use array::ArrayTrait;
use option::OptionTrait;
use traits::Into;
use traits::TryInto;

use integer::u256;
use integer::u128_try_from_felt252;
use integer::u256_from_felt252;
use integer::u64_try_from_felt252;

use serde::Serde;

use starknet::ContractAddress;
use starknet::contract_address::ContractAddressSerde;
use starknet::StorageAccess;
use starknet::StorageBaseAddress;
use starknet::SyscallResult;
use starknet::storage_read_syscall;
use starknet::storage_write_syscall;
use starknet::storage_address_from_base_and_offset;

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

#[derive(Drop, Serde)]
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
            address_domain, storage_address_from_base_and_offset(base, 2_u8), value.nonce.low.into()
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
            address_domain, storage_address_from_base_and_offset(base, 5_u8), value.timeout.into()
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
