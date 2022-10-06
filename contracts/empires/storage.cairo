%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin

from contracts.empires.structures import Realm

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
func realm_contract() -> (address: felt) {
}

@storage_var
func game_contract() -> (address: felt) {
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
