%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256

@storage_var
func combat_outcome() -> (outcome: felt) {
}

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(outcome: felt) {
    combat_outcome.write(outcome);
    return ();
}

@external
func initiate_combat{
    range_check_ptr, syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*
}(
    attacking_army_id: felt,
    attacking_realm_id: Uint256,
    defending_army_id: felt,
    defending_realm_id: Uint256,
) -> (combat_outcome: felt) {
    let (outcome) = combat_outcome.read();
    return (combat_outcome=outcome);
}

@external
func set_combat_outcome{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _outcome: felt
) {
    combat_outcome.write(_outcome);
    return ();
}
