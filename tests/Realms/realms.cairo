%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.alloc import alloc

from contracts.settling_game.utils.game_structs import ResourceIds
from contracts.settling_game.interfaces.IERC1155 import IERC1155

const AMOUNT_FISH = 1124;
const AMOUNT_WHEAT = 902384902;

@storage_var
func combat_outcome() -> (outcome: felt) {
}

@storage_var
func erc1155() -> (address: felt) {
}

@storage_var
func empire() -> (address: felt) {
}

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    outcome: felt, erc1155_: felt, empire_: felt
) {
    combat_outcome.write(outcome);
    erc1155.write(erc1155_);
    empire.write(empire_);
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

// @notice Mocks the call to harvest food module
// @param token_id The staked Realm id (S_Realm)
// @param harvest_type The harvest type is either export or store. Export mints tokens, store keeps on the realm as food
// @param food_building_id The food building id
@external
func harvest{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: Uint256, harvest_type: felt, food_building_id: felt
) {
    alloc_locals;
    let (erc1155_contract_address) = erc1155.read();
    let (address) = empire.read();
    let (ids: Uint256*) = alloc();
    let (amounts: Uint256*) = alloc();
    let (data: felt*) = alloc();
    assert data[0] = 0;
    assert [ids] = Uint256(ResourceIds.fish, 0);
    assert [ids + 2] = Uint256(ResourceIds.wheat, 0);
    assert [amounts] = Uint256(AMOUNT_FISH, 0);
    assert [amounts + 2] = Uint256(AMOUNT_WHEAT, 0);
    IERC1155.mintBatch(
        contract_address=erc1155_contract_address,
        to=address,
        ids_len=2,
        ids=ids,
        amounts_len=2,
        amounts=amounts,
        data_len=1,
        data=data,
    );
    return ();
}
