%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IRouter {
    func swap_exact_tokens_for_tokens(
        amountIn: Uint256,
        amountOutMin: Uint256,
        path_len: felt,
        path: felt*,
        to: felt,
        deadline: felt,
    ) -> (amounts_len: felt, amounts: Uint256*) {
    }

    func swap_tokens_for_exact_tokens(
        amountOut: Uint256,
        amountInMax: Uint256,
        path_len: felt,
        path: felt*,
        to: felt,
        deadline: felt,
    ) -> (amounts_len: felt, amounts: Uint256*) {
    }
}
