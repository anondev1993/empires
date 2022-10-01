%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.hash import hash2
from starkware.starknet.common.syscalls import get_contract_address
from starkware.cairo.common.uint256 import Uint256, uint256_check, uint256_le

from contracts.empires.storage import lords_contract
from src.openzeppelin.token.erc20.IERC20 import IERC20

// @notice: Calculates the pedersen hash of the input array
// @param: data_len The length of the input array
// @param: data The input array
// @param: hash The hash of the input array
// @return The hash of the input array
func _hash_array{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    data_len: felt, data: felt*, hash: felt
) -> felt {
    if (data_len == 0) {
        return hash;
    }
    let (_hash) = hash2{hash_ptr=pedersen_ptr}(hash, [data]);
    return _hash_array(data_len=data_len - 1, data=data + 1, hash=_hash);
}

// @notice: Checks the empire as above amount of funds in $LORDS
// @amount: amount The amount to check the funds against
func _check_empire_funds{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    amount: felt
) {
    let (lords_contract_address) = lords_contract.read();
    let (empire) = get_contract_address();

    let (available_funds: Uint256) = IERC20.balanceOf(
        contract_address=lords_contract_address, account=empire
    );
    tempvar amount_uint256: Uint256 = Uint256(amount, 0);

    with_attr error_message("incorrect value for bounty") {
        uint256_check(amount_uint256);
    }

    // check if the empire has sufficient funds to issue this bounty
    with_attr error_message("insufficient funds for bounty") {
        let (res) = uint256_le(amount_uint256, available_funds);
        assert res = 1;
    }
    return ();
}
