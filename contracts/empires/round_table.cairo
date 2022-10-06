%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero, assert_le
from starkware.starknet.common.syscalls import get_caller_address, get_block_timestamp

from contracts.empires.storage import (
    realms,
    emperor_candidate,
    voting_ledger,
    has_voted,
    voter_list,
    realms_count,
)
from contracts.empires.structures import Votes
from src.openzeppelin.access.ownable.library import Ownable_owner

@external
func start_emperor_change{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    new_emperor: felt, realm_id: felt
) {
    let (ts) = get_block_timestamp();
    let (caller) = get_caller_address();
    let (realm: Realm) = realms.read(realm_id);

    with_attr error_message("calling lord is the zero address") {
        assert_not_zero(caller);
    }
    with_attr error_message("calling lord does not own this realm") {
        assert caller = realm.lord;
    }
    with_attr error_message("emperor candidate is the zero address") {
        assert_not_zero(new_emperor);
    }

    let (votes: Votes) = voting_ledger.read(realm_id);
    _reset_voting(proposing_realm_id=realm_id, votes=votes.yes + votes.no, index=0);
    voting_ledger.write(realm_id, Votes(0, 0));

    let (count) = realms_count.read();
    // if there is only one realm, transfer the ownership
    if (count == 1) {
        Ownable_owner.write(new_emperor);
        return ();
    }
    voting_ledger.write(realm_id, Votes(1, 0));
    has_voted.write(realm_id, realm_id, 1);
    emperor_candidate.write(realm_id, new_emperor);
    return ();
}

@external
func vote_emperor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    // TODO finish voting
    return ();
}

func _reset_voting{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    proposing_realm_id: felt, length: felt, index: felt
) {
    if (length == index) {
        return ();
    }
    let (voting_realm_id) = voter_list.read(proposing_realm_id, index);
    has_voted.write(proposing_realm_id, voting_realm_id, 0);
    voter_list.write(proposing_realm_id, index, 0);
    _reset_voting(proposing_realm_id=proposing_realm_id, length=length, index=index + 1);
    return ();
}
