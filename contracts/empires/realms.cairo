%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math import assert_not_zero, unsigned_div_rem
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import get_block_timestamp, get_contract_address
from starkware.cairo.common.uint256 import Uint256

from contracts.interfaces.realms import IBuildings, IFood, IResources, ITravel, ICombat
from contracts.empires.constants import FOOD_LENGTH, RESOURCES_LENGTH
from contracts.empires.storage import (
    realms,
    erc1155_contract,
    building_module,
    food_module,
    goblin_town_module,
    resource_module,
    travel_module,
    combat_module,
    producer_taxes,
)
from contracts.empires.helpers import get_resources, get_owners, get_resources_refund
from contracts.empires.modifiers import Modifier
from contracts.empires.structures import Realm
from contracts.settling_game.utils.game_structs import HarvestType
from contracts.settling_game.utils.constants import CCombat
from contracts.settling_game.utils.game_structs import ResourceIds
from contracts.settling_game.interfaces.IERC1155 import IERC1155
from src.openzeppelin.access.ownable.library import Ownable
from src.openzeppelin.security.safemath.library import SafeUint256

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
    Modifier.assert_part_of_empire(realm_id=token_id.low);
    Modifier.assert_not_exiting(realm_id=token_id.low);

    let (building_module_) = building_module.read();
    let (success) = IBuildings.build(
        contract_address=building_module_,
        token_id=token_id,
        building_id=building_id,
        quantity=quantity,
    );

    let (realm) = realms.read(token_id.low);
    let (ts) = get_block_timestamp();
    realms.write(token_id.low, Realm(realm.lord, realm.annexation_date, 0, ts + 24 * 3600));

    return (success=success);
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
    Modifier.assert_part_of_empire(realm_id=token_id.low);
    Modifier.assert_not_exiting(realm_id=token_id.low);

    let (food_module_) = food_module.read();
    IFood.create(
        contract_address=food_module_, token_id=token_id, qty=qty, food_building_id=food_building_id
    );

    let (realm) = realms.read(token_id.low);
    let (ts) = get_block_timestamp();
    realms.write(token_id.low, Realm(realm.lord, realm.annexation_date, 0, ts + 24 * 3600));
    return ();
}

// @notice Harvests either farms or fishing villages
// @param token_id The staked Realm id (S_Realm)
// @param harvest_type The harvest type is either export or store. Export mints tokens, store keeps on the realm as food
// @param food_building_id The food building id
@external
func harvest{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(token_id: Uint256, food_building_id: felt) {
    alloc_locals;
    Ownable.assert_only_owner();
    Modifier.assert_part_of_empire(realm_id=token_id.low);

    // prepare the call to balanceOfBatch
    let (resources_address) = erc1155_contract.read();
    let (owners: felt*) = alloc();
    let (token_ids: Uint256*) = alloc();
    let (empire_address) = get_contract_address();
    assert [owners] = empire_address;
    assert [owners + 1] = empire_address;
    assert [token_ids] = Uint256(ResourceIds.wheat, 0);
    assert [token_ids + Uint256.SIZE] = Uint256(ResourceIds.fish, 0);

    let (local pre_balance_len, local pre_balance) = IERC1155.balanceOfBatch(
        contract_address=resources_address,
        owners_len=FOOD_LENGTH,
        owners=owners,
        tokens_id_len=FOOD_LENGTH,
        tokens_id=token_ids,
    );
    with_attr error_message("food balance length error") {
        assert pre_balance_len = FOOD_LENGTH;
    }

    // harvest for the realm_id
    // force to mint tokens in order to collect the tax
    let (food_module_) = food_module.read();
    IFood.harvest(
        contract_address=food_module_,
        token_id=token_id,
        harvest_type=HarvestType.Export,
        food_building_id=food_building_id,
    );

    // recall balanceOfBatch to retrieve increase in resources
    let (local post_balance_len, local post_balance) = IERC1155.balanceOfBatch(
        contract_address=resources_address,
        owners_len=FOOD_LENGTH,
        owners=owners,
        tokens_id_len=FOOD_LENGTH,
        tokens_id=token_ids,
    );
    with_attr error_message("food balance length error") {
        assert post_balance_len = FOOD_LENGTH;
    }

    // calculate resources increase and send to user diff * (100 - tax) // 100
    let (amounts: Uint256*) = alloc();
    let (data: felt*) = alloc();
    assert data[0] = 0;
    let (food_tax) = producer_taxes.read();
    let (diff_wheat: Uint256) = SafeUint256.sub_le([post_balance], [pre_balance]);
    let (diff_fish: Uint256) = SafeUint256.sub_le(
        [post_balance + Uint256.SIZE], [pre_balance + Uint256.SIZE]
    );
    let (realm_wheat, _) = unsigned_div_rem(diff_wheat.low * (100 - food_tax), 100);
    let (realm_fish, _) = unsigned_div_rem(diff_fish.low * (100 - food_tax), 100);
    assert [amounts] = Uint256(realm_wheat, 0);
    assert [amounts + Uint256.SIZE] = Uint256(realm_fish, 0);

    // send excess resources back to user
    let (realm: Realm) = realms.read(token_id.low);
    IERC1155.safeBatchTransferFrom(
        contract_address=resources_address,
        _from=empire_address,
        to=realm.lord,
        ids_len=FOOD_LENGTH,
        ids=token_ids,
        amounts_len=FOOD_LENGTH,
        amounts=amounts,
        data_len=1,
        data=data,
    );
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
    Modifier.assert_part_of_empire(realm_id=token_id.low);
    Modifier.assert_not_exiting(realm_id=token_id.low);

    let (food_module_) = food_module.read();
    IFood.convert_food_tokens_to_store(
        contract_address=food_module_, token_id=token_id, quantity=quantity, resource_id=resource_id
    );
    return ();
}

// RESOURCES

// @notice Claim available resources
// @token_id The staked realm token id
@external
func claim_resources{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: Uint256
) {
    alloc_locals;
    Ownable.assert_only_owner();
    Modifier.assert_part_of_empire(realm_id=token_id.low);

    // prepare the call to balanceOfBatch
    let (resources_address) = erc1155_contract.read();
    let (owners: felt*) = get_owners();
    let (token_ids: Uint256*) = get_resources();

    let (local pre_balance_len, local pre_balance) = IERC1155.balanceOfBatch(
        contract_address=resources_address,
        owners_len=RESOURCES_LENGTH,
        owners=owners,
        tokens_id_len=RESOURCES_LENGTH,
        tokens_id=token_ids,
    );
    with_attr error_message("resources balance length error") {
        assert pre_balance_len = RESOURCES_LENGTH;
    }

    // claim the resources
    let (resource_module_) = resource_module.read();
    IResources.claim_resources(contract_address=resource_module_, token_id=token_id);

    // recall balanceOfBatch to retrieve increase in resources
    let (local post_balance_len, local post_balance) = IERC1155.balanceOfBatch(
        contract_address=resources_address,
        owners_len=RESOURCES_LENGTH,
        owners=owners,
        tokens_id_len=RESOURCES_LENGTH,
        tokens_id=token_ids,
    );
    with_attr error_message("resources balance length error") {
        assert pre_balance_len = RESOURCES_LENGTH;
    }

    // calculate the taxable amount of resources
    let (local refund_resources: Uint256*) = alloc();
    let (producer_taxes_) = producer_taxes.read();
    get_resources_refund(
        len=RESOURCES_LENGTH,
        post_resources=post_balance,
        pre_resources=pre_balance,
        diff_resources=refund_resources,
        tax=producer_taxes_,
    );

    // send excess resources back to user
    let (empire_address) = get_contract_address();
    let (realm: Realm) = realms.read(token_id.low);
    let (data: felt*) = alloc();
    assert data[0] = 0;
    IERC1155.safeBatchTransferFrom(
        contract_address=resources_address,
        _from=empire_address,
        to=realm.lord,
        ids_len=RESOURCES_LENGTH,
        ids=token_ids,
        amounts_len=RESOURCES_LENGTH,
        amounts=refund_resources,
        data_len=1,
        data=data,
    );
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
    Modifier.assert_part_of_empire(realm_id=traveller_token_id.low);

    let (travel_module_) = travel_module.read();
    ITravel.travel(
        contract_address=travel_module_,
        traveller_contract_id=traveller_contract_id,
        traveller_token_id=traveller_token_id,
        traveller_nested_id=traveller_nested_id,
        destination_contract_id=destination_contract_id,
        destination_token_id=destination_token_id,
        destination_nested_id=destination_nested_id,
    );
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
    alloc_locals;
    Ownable.assert_only_owner();
    Modifier.assert_part_of_empire(realm_id=realm_id.low);
    Modifier.assert_not_exiting(realm_id=realm_id.low);

    let (combat_module_) = combat_module.read();
    ICombat.build_army_from_battalions(
        contract_address=combat_module_,
        realm_id=realm_id,
        army_id=army_id,
        battalion_ids_len=battalion_ids_len,
        battalion_ids=battalion_ids,
        battalion_quantity_len=battalion_quantity_len,
        battalion_quantity=battalion_quantity,
    );
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
    Modifier.assert_part_of_empire(realm_id=attacking_realm_id.low);
    let (defending) = realms.read(defending_realm_id.low);
    with_attr error_message("friendly fire is not permitted in the empire") {
        assert defending.lord = 0;
        assert defending.annexation_date = 0;
    }

    let (resources_address) = erc1155_contract.read();
    // let (resources_len, resources) = IERC1155.balanceOfBatch(
    //     contract_address=resources_address, owners_len=22, owners=0, tokens_id_len=22, tokens_id=0
    // );

    let (combat_module_) = combat_module.read();
    let (combat_outcome) = ICombat.initiate_combat(
        contract_address=combat_module_,
        attacking_army_id=attacking_army_id,
        attacking_realm_id=attacking_realm_id,
        defending_army_id=defending_army_id,
        defending_realm_id=defending_realm_id,
    );
    // TODO add the taxes
    return (combat_outcome=combat_outcome);
}
