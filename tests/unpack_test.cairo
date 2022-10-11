%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.starknet.common.syscalls import get_contract_address
from starkware.cairo.common.bitwise import bitwise_and
from starkware.cairo.common.math import assert_le, unsigned_div_rem
from starkware.cairo.common.pow import pow

@external
func __setup__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    let (local address) = get_contract_address();
    %{ context.self_address = ids.address %}
    return ();
}

@external
func test_fetch_realm_data{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;

    let data = 223106505640168374666723097842946;
    // 101412048018258352123039691248900
    // 283953734451234283136552987462402
    // 223106505640168374666723097842946
    let (local regions) = unpack_data(data, 0, 255);
    let (local cities) = unpack_data(data, 8, 255);
    let (local harbours) = unpack_data(data, 16, 255);
    let (local rivers) = unpack_data(data, 24, 255);
    let (local resource_number) = unpack_data(data, 32, 255);
    let (local resource_1) = unpack_data(data, 40, 255);
    let (local resource_2) = unpack_data(data, 48, 255);
    let (local resource_3) = unpack_data(data, 56, 255);
    let (local resource_4) = unpack_data(data, 64, 255);
    let (local resource_5) = unpack_data(data, 72, 255);
    let (local resource_6) = unpack_data(data, 80, 255);
    let (local resource_7) = unpack_data(data, 88, 255);
    let (local wonder) = unpack_data(data, 96, 255);
    let (local order) = unpack_data(data, 104, 255);
    return ();
}

// upack data
// parse data, index, mask_size
func unpack_data{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(data: felt, index: felt, mask_size: felt) -> (score: felt) {
    alloc_locals;

    // 1. Create a 8-bit mask at and to the left of the index
    // E.g., 000111100 = 2**2 + 2**3 + 2**4 + 2**5
    // E.g.,  2**(i) + 2**(i+1) + 2**(i+2) + 2**(i+3) = (2**i)(15)
    let (power) = pow(2, index);
    // 1 + 2 + 4 + 8 + 16 + 32 + 64 + 128 + 256 + 512 + 1024 + 2048 = 15
    let mask = mask_size * power;

    // 2. Apply mask using bitwise operation: mask AND data.
    let (masked) = bitwise_and(mask, data);

    // 3. Shift element right by dividing by the order of the mask.
    let (result, _) = unsigned_div_rem(masked, power);

    return (score=result);
}
