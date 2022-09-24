%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin

from contracts.empires.structures import Realm

@storage_var
func realms(realm_id: felt) -> (realm: Realm) {
}

@storage_var
func realm_contract() -> (address: felt) {
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
