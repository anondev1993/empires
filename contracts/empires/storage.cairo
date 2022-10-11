%lang starknet

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from contracts.empires.structures import Realm, Votes, Acquisition
from contracts.empires.constants import IACCOUNT_ID

from contracts.settling_game.utils.game_structs import RealmData
from contracts.settling_game.interfaces.IRealms import IRealms
from src.openzeppelin.access.ownable.library import Ownable

// -----------------------------------
// Storage
// -----------------------------------

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
func erc1155_contract() -> (address: felt) {
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

// -----------------------------------
// Views
// -----------------------------------
@view
func supportsInterface{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    interface_id: felt
) -> (success: felt) {
    if (interface_id == IACCOUNT_ID) {
        return (success=TRUE);
    }
    return (success=FALSE);
}

@view
func get_realm_data{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    realm_id: felt
) -> (realm_stats: RealmData) {
    let (realms_address) = realm_contract.read();
    let (data: RealmData) = IRealms.fetch_realm_data(
        contract_address=realms_address, token_id=Uint256(realm_id, 0)
    );
    return (realm_stats=data);
}

@view
func get_realms_count{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    count: felt
) {
    return realms_count.read();
}

@view
func get_bounties{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    realm_id: felt
) -> (amount: felt) {
    return bounties.read(realm_id);
}

@view
func get_emperor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    emperor: felt
) {
    let (emperor) = Ownable.owner();
    return (emperor=emperor);
}

@view
func get_emperor_candidate{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    proposing_realm_id: felt
) -> (candidate: felt) {
    return emperor_candidate.read(proposing_realm_id);
}
