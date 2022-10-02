%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE, FALSE

from contracts.empires.storage import (
    building_module,
    food_module,
    goblin_town_module,
    resource_module,
    travel_module,
    combat_module,
)
from src.openzeppelin.access.ownable.library import Ownable

// BUILDING

// @notice Build building on a realm
// @param token_id The staked Realm id (S_Realm)
// @param building_id The building id
// @return success Returns TRUE when successfull
@external
func build{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(token_id: Uint256, building_id: felt, quantity: felt) -> (success: felt) {
    Ownable.assert_only_owner();
    // TODO check the realm is not in recovery mode
    // TODO call build from the building_module
    // TODO update the realm exit time
    return (success=TRUE);
}

// FOOD

// @notice Creates either farms or fishing villages
// @param token_id The staked Realm id (S_Realm)
// @param qty The quantity to build on realm
// @param food_building_id The food building id
@external
func create{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(token_id: Uint256, qty: felt, food_building_id: felt) {
    Ownable.assert_only_owner();
    // TODO check the realm is not in recovery mode
    // TODO call create from the food_module
    // TODO update the realm exit time
    return ();
}

// @notice Harvests either farms or fishing villages
// @param token_id The staked Realm id (S_Realm)
// @param harvest_type The harvest type is either export or store. Export mints tokens, store keeps on the realm as food
// @param food_building_id The food building id
@external
func harvest{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(token_id: Uint256, harvest_type: felt, food_building_id: felt) {
    Ownable.assert_only_owner();
    // TODO call harvest from the food_module
    return ();
}

// @notice Converts harvest directly into food store on a Realm
// @param token_id The staked Realm id (S_Realm)
// @param quantity The quantity of food to store
// @param resource_id The id of food to be stored (FISH or WHEAT)
@external
func convert_food_tokens_to_store{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: Uint256, quantity: felt, resource_id: felt
) {
    Ownable.assert_only_owner();
    // TODO check the realm is not in recovery mode
    // TODO call convert_food_tokens_to_store from the food_module
    return ();
}

// RESOURCES

// @notice Claim available resources
// @token_id The staked realm token id
@external
func claim_resources{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: Uint256
) {
    Ownable.assert_only_owner();
    // TODO call claim_resources from the resource_module
    // TODO add the taxes
    return ();
}

// @notice Pillage resources after a succesful raid
// @param token_id The staked realm id
// @param claimer The resource receiver address
@external
func pillage_resources{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: Uint256, claimer: felt
) {
    Ownable.assert_only_owner();
    // TODO call pillage_resources from the resource_module
    // TODO add the taxes
    return ();
}

// TRAVEL

// @param traveller_contract_id The external contract ID
// @param traveller_token_id The token ID moving (Realm, Adventurer)
// @param traveller_nested_id The nested asset ID (Armies, persons etc)
// @param destination_contract_id The destination contract id
// @param destination_token_id The destination token ID
// @param destination_nested_id The nested asset ID (Armies, persons etc)
@external
func travel{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    traveller_contract_id: felt,
    traveller_token_id: Uint256,
    traveller_nested_id: felt,
    destination_contract_id: felt,
    destination_token_id: Uint256,
    destination_nested_id: felt,
) {
    Ownable.assert_only_owner();
    // TODO call travel from the travel_module
    return ();
}

// COMBAT

// @notice Creates a new Army on Realm. Armies are comprised of Battalions.
// @param realm_id The staked Realm ID (S_Realm)
// @param army_id The army ID being added too.
// @param battalion_ids_len The battlion IDs length
// @param battalion_ids The battlion IDs
// @param battalions_len The battalions lengh
// @param battalions The battalions to add
@external
func build_army_from_battalions{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(
    realm_id: Uint256,
    army_id: felt,
    battalion_ids_len: felt,
    battalion_ids: felt*,
    battalion_quantity_len: felt,
    battalion_quantity: felt*,
) {
    Ownable.assert_only_owner();
    // TODO check the realm is not in recovery mode
    // TODO call build_army_from_battalions from the combat_module
    return ();
}

// @notice Commence the attack
// @param attacking_realm_id The staked Realm id (S_Realm)
// @param defending_realm_id The staked Realm id (S_Realm)
// @return: combat_outcome The outcome of the combat - either the attacker (CCombat.COMBAT_OUTCOME_ATTACKER_WINS)
//                          or the defender (CCombat.COMBAT_OUTCOME_DEFENDER_WINS)
@external
func initiate_combat{
    range_check_ptr, syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*
}(
    attacking_army_id: felt,
    attacking_realm_id: Uint256,
    defending_army_id: felt,
    defending_realm_id: Uint256,
) -> (combat_outcome: felt) {
    Ownable.assert_only_owner();
    // TODO check the realm is not attacking someone from the empire
    // TODO call initiate_combat from the combat_module
    return ();
}
