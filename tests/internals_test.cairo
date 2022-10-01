%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_contract_address
from starkware.cairo.common.uint256 import Uint256, uint256_check, uint256_le

from contracts.empires.internals import _check_empire_funds

const EMPEROR = 123456;
const ACCOUNT = 1;
const AMOUNT = 10000;

@contract_interface
namespace IERC20 {
    func balanceOf(account: felt) -> (balance: Uint256) {
    }
}

@external
func __setup__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    let (local address) = get_contract_address();
    %{
        context.self_address = ids.address 
        context.lord_contract = deploy_contract("./tests/ERC20/ERC20Mintable.cairo", [0, 0, 6, ids.AMOUNT, 0, ids.address, ids.address]).contract_address
        store(context.self_address, "lords_contract", [context.lord_contract])
    %}
    return ();
}

@external
func test_check_empire_funds{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    _check_empire_funds(AMOUNT);
    return ();
}

@external
func test_check_empire_funds_incorrect_uint256{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    %{ expect_revert(error_message="incorrect value for bounty") %}
    _check_empire_funds(2 ** 128);
    return ();
}

@external
func test_check_empire_funds_insufficient_funds{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    %{ expect_revert(error_message="insufficient funds for bounty") %}
    _check_empire_funds(AMOUNT + 1);
    return ();
}
