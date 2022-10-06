%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.hash import hash2
from starkware.starknet.common.syscalls import get_contract_address
from starkware.cairo.common.uint256 import Uint256, uint256_check, uint256_le
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.messages import send_message_to_l1
from starkware.cairo.common.math import assert_not_zero

from contracts.empires.storage import lords_contract
from src.openzeppelin.token.erc20.IERC20 import IERC20
from contracts.interfaces.router import IRouter

// @notice Calculates the pedersen hash of the input array
// @param data_len The length of the input array
// @param data The input array
// @param hash The hash of the input array
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

// @notice Checks the empire as above amount of funds in $LORDS
// @param amount The amount to check the funds against
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

// @notice Approve tokens then swaps a number of LORDS tokens for exact amount of ethereum tokens
// @param router_address Address of router from jediswap
// @param lords_token_address Address of LORDS ERC20
// @param eth_token_address Address of ETH ERC20
// @param max_lords_amount Max amount of LORDS tokens allowed to swap
// @param eth_amount Exact amount of eth to retrieve
func swap_lords_for_exact_eth{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    router_address: felt,
    lords_token_address: felt,
    eth_token_address: felt,
    max_lords_amount: Uint256,
    eth_amount: Uint256,
) -> (amounts_len: felt, amounts: Uint256*) {
    // TODO: check if you don't want negative numbers?
    // or require higher than 0 ?

    let (empire) = get_contract_address();
    IERC20.approve(
        contract_address=lords_token_address, spender=router_address, amount=max_lords_amount
    );

    let path: felt* = alloc();
    assert [path] = lords_token_address;
    assert [path + 1] = eth_token_address;

    // swap the tokens
    // TODO: verify that deadline is not issue
    let (amounts_len: felt, amounts: Uint256*) = IRouter.swap_tokens_for_exact_tokens(
        contract_address=router_address,
        amountOut=eth_amount,
        amountInMax=max_lords_amount,
        path_len=2,
        path=path,
        to=empire,
        deadline=0,
    );

    return (amounts_len, amounts);
}

// @notice Sends a message to L1 empire contract to buy a realm on OpenSea
// @param l1_address The address of the l1 empire contract
// @param token_id The id of the token to buy
// @param amount The amount in eth to spend for the token
func message_l1_acquire_realm{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    l1_address: felt, token_id: felt, amount: felt
) -> () {
    // 0 = buy message
    const MESSAGE = 0;
    let (message_payload: felt*) = alloc();
    assert message_payload[0] = MESSAGE;
    assert message_payload[1] = token_id;
    assert message_payload[2] = amount;

    send_message_to_l1(to_address=l1_address, payload_size=3, payload=message_payload);

    return ();
}
