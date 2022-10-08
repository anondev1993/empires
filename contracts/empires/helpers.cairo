%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_contract_address
from starkware.cairo.common.registers import get_label_location
from starkware.cairo.common.alloc import alloc

func get_resources{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    resources: felt*
) {
    let (RESOURCES_ARR) = get_label_location(resource_start);
    return (resources=cast(RESOURCES_ARR, felt*));

    resource_start:
    dw 1;
    dw 2;
    dw 3;
    dw 4;
    dw 5;
    dw 6;
    dw 7;
    dw 8;
    dw 9;
    dw 10;
    dw 11;
    dw 12;
    dw 13;
    dw 14;
    dw 15;
    dw 16;
    dw 17;
    dw 18;
    dw 19;
    dw 20;
    dw 21;
    dw 22;
}

func get_owners{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    owners: felt*
) {
    let (empire) = get_contract_address();
    let (owners: felt*) = alloc();
    assert [owners] = empire;
    assert [owners + 1] = empire;
    assert [owners + 2] = empire;
    assert [owners + 3] = empire;
    assert [owners + 4] = empire;
    assert [owners + 5] = empire;
    assert [owners + 6] = empire;
    assert [owners + 7] = empire;
    assert [owners + 8] = empire;
    assert [owners + 9] = empire;
    assert [owners + 10] = empire;
    assert [owners + 11] = empire;
    assert [owners + 12] = empire;
    assert [owners + 13] = empire;
    assert [owners + 14] = empire;
    assert [owners + 15] = empire;
    assert [owners + 16] = empire;
    assert [owners + 17] = empire;
    assert [owners + 18] = empire;
    assert [owners + 19] = empire;
    assert [owners + 20] = empire;
    assert [owners + 21] = empire;
    return (owners=owners);
}
