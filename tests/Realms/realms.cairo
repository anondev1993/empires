%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.alloc import alloc

from contracts.empires.constants import FOOD_LENGTH, RESOURCES_LENGTH
from contracts.empires.helpers import get_owners, get_resources
from contracts.settling_game.utils.game_structs import ResourceIds
from contracts.settling_game.interfaces.IERC1155 import IERC1155

const AMOUNT_FISH = 1124;
const AMOUNT_WHEAT = 902384902;

const AMOUNT_WOOD = 1290348;
const AMOUNT_STONE = 30284;
const AMOUNT_COAL = 93285;
const AMOUNT_COPPER = 90285;
const AMOUNT_OBSIDIAN = 9086;
const AMOUNT_SILVER = 9086423;
const AMOUNT_IRONWOOD = 90846;
const AMOUNT_COLD_IRON = 92856;
const AMOUNT_GOLD = 264;
const AMOUNT_HARTWOOD = 46147;
const AMOUNT_DIAMONDS = 908146;
const AMOUNT_SAPPHIRE = 41256891476;
const AMOUNT_RUBY = 1408967;
const AMOUNT_DEEP_CRYSTAL = 50139856;
const AMOUNT_IGNIUM = 90231856;
const AMOUNT_ETHEREAL_SILICA = 34289612;
const AMOUNT_TRUE_ICE = 490618;
const AMOUNT_TWILIGHT_QUARTZ = 4890167;
const AMOUNT_ALCHEMICAL_SILVER = 436990;
const AMOUNT_ADAMANTINE = 90468;
const AMOUNT_MITHRAL = 4901268;
const AMOUNT_DRAGONHIDE = 9012346;

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
func build{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(token_id: Uint256, building_id: felt, quantity: felt) -> (success: felt) {
    return (success=1);
}

@external
func create{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(token_id: Uint256, qty: felt, food_building_id: felt) {
    return ();
}

@external
func convert_food_tokens_to_store{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(token_id: Uint256, quantity: felt, resource_id: felt) {
    return ();
}

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
    assert [ids + Uint256.SIZE] = Uint256(ResourceIds.wheat, 0);
    assert [amounts] = Uint256(AMOUNT_FISH, 0);
    assert [amounts + Uint256.SIZE] = Uint256(AMOUNT_WHEAT, 0);
    IERC1155.mintBatch(
        contract_address=erc1155_contract_address,
        to=address,
        ids_len=FOOD_LENGTH,
        ids=ids,
        amounts_len=FOOD_LENGTH,
        amounts=amounts,
        data_len=1,
        data=data,
    );
    return ();
}

// @notice Mocks the call to claim_resources resource module
// @token_id The staked realm token id
@external
func claim_resources{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: Uint256
) {
    alloc_locals;
    let (erc1155_contract_address) = erc1155.read();
    let (address) = empire.read();
    let (ids: Uint256*) = get_resources();
    let (amounts: Uint256*) = _get_amounts();
    let (data: felt*) = alloc();
    assert data[0] = 0;
    IERC1155.mintBatch(
        contract_address=erc1155_contract_address,
        to=address,
        ids_len=RESOURCES_LENGTH,
        ids=ids,
        amounts_len=RESOURCES_LENGTH,
        amounts=amounts,
        data_len=1,
        data=data,
    );
    return ();
}

// @notice Mocks the call to initiate_combat combat module
// @param attacking_realm_id The staked Realm id (S_Realm)
// @param defending_realm_id The staked Realm id (S_Realm)
// @return: combat_outcome The outcome of the combat - either the attacker (CCombat.COMBAT_OUTCOME_ATTACKER_WINS)
//                          or the defender (CCombat.COMBAT_OUTCOME_DEFENDER_WINS)
@external
func initiate_combat{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    attacking_army_id: felt,
    attacking_realm_id: Uint256,
    defending_army_id: felt,
    defending_realm_id: Uint256,
) -> (combat_outcome: felt) {
    alloc_locals;
    let (erc1155_contract_address) = erc1155.read();
    let (address) = empire.read();
    let (ids: Uint256*) = get_resources();
    let (amounts: Uint256*) = _get_amounts();
    let (data: felt*) = alloc();
    assert data[0] = 0;
    IERC1155.mintBatch(
        contract_address=erc1155_contract_address,
        to=address,
        ids_len=RESOURCES_LENGTH,
        ids=ids,
        amounts_len=RESOURCES_LENGTH,
        amounts=amounts,
        data_len=1,
        data=data,
    );
    return (combat_outcome=1);
}

func _get_amounts{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    amounts: Uint256*
) {
    alloc_locals;
    let (erc1155_contract_address) = erc1155.read();
    let (address) = empire.read();
    let (ids: Uint256*) = get_resources();
    let (amounts: Uint256*) = alloc();
    assert [amounts] = Uint256(AMOUNT_WOOD, 0);
    assert [amounts + Uint256.SIZE] = Uint256(AMOUNT_STONE, 0);
    assert [amounts + 2 * Uint256.SIZE] = Uint256(AMOUNT_COAL, 0);
    assert [amounts + 3 * Uint256.SIZE] = Uint256(AMOUNT_COPPER, 0);
    assert [amounts + 4 * Uint256.SIZE] = Uint256(AMOUNT_OBSIDIAN, 0);
    assert [amounts + 5 * Uint256.SIZE] = Uint256(AMOUNT_SILVER, 0);
    assert [amounts + 6 * Uint256.SIZE] = Uint256(AMOUNT_IRONWOOD, 0);
    assert [amounts + 7 * Uint256.SIZE] = Uint256(AMOUNT_COLD_IRON, 0);
    assert [amounts + 8 * Uint256.SIZE] = Uint256(AMOUNT_GOLD, 0);
    assert [amounts + 9 * Uint256.SIZE] = Uint256(AMOUNT_HARTWOOD, 0);
    assert [amounts + 10 * Uint256.SIZE] = Uint256(AMOUNT_DIAMONDS, 0);
    assert [amounts + 11 * Uint256.SIZE] = Uint256(AMOUNT_SAPPHIRE, 0);
    assert [amounts + 12 * Uint256.SIZE] = Uint256(AMOUNT_RUBY, 0);
    assert [amounts + 13 * Uint256.SIZE] = Uint256(AMOUNT_DEEP_CRYSTAL, 0);
    assert [amounts + 14 * Uint256.SIZE] = Uint256(AMOUNT_IGNIUM, 0);
    assert [amounts + 15 * Uint256.SIZE] = Uint256(AMOUNT_ETHEREAL_SILICA, 0);
    assert [amounts + 16 * Uint256.SIZE] = Uint256(AMOUNT_TRUE_ICE, 0);
    assert [amounts + 17 * Uint256.SIZE] = Uint256(AMOUNT_TWILIGHT_QUARTZ, 0);
    assert [amounts + 18 * Uint256.SIZE] = Uint256(AMOUNT_ALCHEMICAL_SILVER, 0);
    assert [amounts + 19 * Uint256.SIZE] = Uint256(AMOUNT_ADAMANTINE, 0);
    assert [amounts + 20 * Uint256.SIZE] = Uint256(AMOUNT_MITHRAL, 0);
    assert [amounts + 21 * Uint256.SIZE] = Uint256(AMOUNT_DRAGONHIDE, 0);
    return (amounts=amounts);
}
