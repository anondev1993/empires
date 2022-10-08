%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin

from contracts.empires.structures import Realm, Votes, Acquisition

@storage_var
func eth_contract() -> (address: felt) {
}

@storage_var
func router_contract() -> (address: felt) {
}

@storage_var
func l1_empire_contract() -> (address: felt) {
}

@storage_var
func token_bridge_contract() -> (address: felt) {
}

@storage_var
func realms(realm_id: felt) -> (realm: Realm) {
}

@storage_var
func lords(lord: felt) -> (realms: felt) {
}

@storage_var
func realms_count() -> (count: felt) {
}

@storage_var
func building_module() -> (address: felt) {
}

@storage_var
func food_module() -> (address: felt) {
}

@storage_var
func goblin_town_module() -> (address: felt) {
}

@storage_var
func resource_module() -> (address: felt) {
}

@storage_var
func travel_module() -> (address: felt) {
}

@storage_var
func combat_module() -> (address: felt) {
}

@storage_var
func realm_contract() -> (address: felt) {
}

@storage_var
func stacked_realm_contract() -> (address: felt) {
}

@storage_var
func lords_contract() -> (address: felt) {
}

@storage_var
func producer_taxes() -> (taxes: felt) {
}

@storage_var
func attacker_taxes() -> (taxes: felt) {
}

@storage_var
func goblin_taxes() -> (taxes: felt) {
}

@storage_var
func is_enemy(realm_id: felt) -> (is_enemy: felt) {
}

@storage_var
func bounties(realm_id: felt) -> (amount: felt) {
}

// vote system to elect new emperor

@storage_var
func emperor_candidate(proposing_realm_id: felt) -> (candidate: felt) {
}

@storage_var
func voting_ledger_emperor(proposing_realm_id: felt) -> (vote: Votes) {
}

@storage_var
func has_voted_emperor(proposing_realm_id: felt, realm_id: felt) -> (voted: felt) {
}

@storage_var
func voter_list_emperor(proposing_realm_id: felt, index: felt) -> (realm_id: felt) {
}

// vote system to buy realms on L1
@storage_var
func acquisition_candidate(proposing_realm_id: felt) -> (candidate: Acquisition) {
}

@storage_var
func voting_ledger_acquisition(proposing_realm_id: felt) -> (vote: Votes) {
}

@storage_var
func has_voted_acquisition(proposing_realm_id: felt, realm_id: felt) -> (voted: felt) {
}

@storage_var
func voter_list_acquisition(proposing_realm_id: felt, index: felt) -> (realm_id: felt) {
}
