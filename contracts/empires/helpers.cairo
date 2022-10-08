%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_contract_address
from starkware.cairo.common.registers import get_label_location
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.uint256 import Uint256
from src.openzeppelin.security.safemath.library import SafeUint256

func get_resources{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    resources: Uint256*
) {
    let (RESOURCES_ARR) = get_label_location(resource_start);
    return (resources=cast(RESOURCES_ARR, Uint256*));

    resource_start:
    dw 1;
    dw 0;
    dw 2;
    dw 0;
    dw 3;
    dw 0;
    dw 4;
    dw 0;
    dw 5;
    dw 0;
    dw 6;
    dw 0;
    dw 7;
    dw 0;
    dw 8;
    dw 0;
    dw 9;
    dw 0;
    dw 10;
    dw 0;
    dw 11;
    dw 0;
    dw 12;
    dw 0;
    dw 13;
    dw 0;
    dw 14;
    dw 0;
    dw 15;
    dw 0;
    dw 16;
    dw 0;
    dw 17;
    dw 0;
    dw 18;
    dw 0;
    dw 19;
    dw 0;
    dw 20;
    dw 0;
    dw 21;
    dw 0;
    dw 22;
    dw 0;
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

func get_resources_diff{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    len: felt, post_resources: Uint256*, pre_resources: Uint256*, diff_resources: Uint256*
) {
    if (len == 0) {
        return ();
    }
    let (diff: Uint256) = SafeUint256.sub_le([post_resources], [pre_resources]);
    assert [diff_resources] = diff;
    get_resources_diff(
        len=len - 1,
        post_resources=post_resources + Uint256.SIZE,
        pre_resources=pre_resources + Uint256.SIZE,
        diff_resources=diff_resources + Uint256.SIZE,
    );
    return ();
}
