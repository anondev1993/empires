%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace ITokenBridge {
    func initiate_withdraw(l1_recipient: felt, amount: Uint256) {
    }
}
