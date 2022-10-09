%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IBuildings {
    func build(token_id: Uint256, building_id: felt, quantity: felt) -> (success: felt) {
    }
}

@contract_interface
namespace IFood {
    func create(token_id: Uint256, qty: felt, food_building_id: felt) {
    }
    func harvest(token_id: Uint256, harvest_type: felt, food_building_id: felt) {
    }
    func convert_food_tokens_to_store(token_id: Uint256, quantity: felt, resource_id: felt) {
    }
}

@contract_interface
namespace IResources {
    func claim_resources(token_id: Uint256) {
    }
}

@contract_interface
namespace ITravel {
    func travel(
        traveller_contract_id: felt,
        traveller_token_id: Uint256,
        traveller_nested_id: felt,
        destination_contract_id: felt,
        destination_token_id: Uint256,
        destination_nested_id: felt,
    ) {
    }
}

@contract_interface
namespace ICombat {
    func initiate_combat(
        attacking_army_id: felt,
        attacking_realm_id: Uint256,
        defending_army_id: felt,
        defending_realm_id: Uint256,
    ) -> (combat_outcome: felt) {
    }
    func build_army_from_battalions(
        realm_id: Uint256,
        army_id: felt,
        battalion_ids_len: felt,
        battalion_ids: felt*,
        battalion_quantity_len: felt,
        battalion_quantity: felt*,
    ) {
    }
}
