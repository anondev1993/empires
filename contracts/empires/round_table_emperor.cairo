%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero, assert_le, unsigned_div_rem
from starkware.cairo.common.math_cmp import is_le
from starkware.starknet.common.syscalls import get_caller_address, get_block_timestamp
from src.openzeppelin.access.ownable.library import Ownable

from contracts.empires.storage import (
    realms,
    emperor_candidate,
    voting_ledger_emperor,
    has_voted_emperor,
    voter_list_emperor,
    realms_count,
)
from contracts.empires.structures import Votes, Realm
from src.openzeppelin.access.ownable.library import Ownable_owner

// @notice Starts a new emperor voting process
// @param new_emperor The new proposed emperor
// @param realm_id The proposing realm
@external
func propose_emperor_change{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    new_emperor: felt, realm_id: felt
) {
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

    let (votes: Votes) = voting_ledger_emperor.read(realm_id);
    _reset_voting_emperor(proposing_realm_id=realm_id, length=votes.yes + votes.no, index=0);

    let (count) = realms_count.read();
    // if there is only one realm, transfer the ownership
    if (count == 1) {
        Ownable_owner.write(new_emperor);
        return ();
    }
    voting_ledger_emperor.write(realm_id, Votes(1, 0));
    has_voted_emperor.write(realm_id, realm_id, 1);
    voter_list_emperor.write(realm_id, 0, realm_id);
    emperor_candidate.write(realm_id, new_emperor);
    return ();
}

// @notice Vote yes or no for a proposal
// @param proposing_realm_id The id of the realm who made the proposition
// @param realm_id The id of a realm owned by the caller
// @param yes_or_no The vote for that proposal
@external
func vote_emperor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    proposing_realm_id: felt, realm_id: felt, yes_or_no: felt
) {
    alloc_locals;
    let (caller) = get_caller_address();
    let (realm: Realm) = realms.read(realm_id);

    with_attr error_message("calling lord is the zero address") {
        assert_not_zero(caller);
    }
    with_attr error_message("calling lord does not own this realm") {
        assert caller = realm.lord;
    }
    with_attr error_message("invalid vote") {
        assert [range_check_ptr] = yes_or_no;
        assert [range_check_ptr + 1] = 1 - yes_or_no;
    }

    let range_check_ptr = range_check_ptr + 2;

    let (emperor) = emperor_candidate.read(proposing_realm_id);
    with_attr error_message("proposed emperor is the zero address") {
        assert_not_zero(emperor);
    }

    let (has_voted_emperor_) = has_voted_emperor.read(proposing_realm_id, realm_id);
    with_attr error_message("realm has already voted") {
        assert has_voted_emperor_ = 0;
    }

    let (local votes: Votes) = voting_ledger_emperor.read(proposing_realm_id);
    let (realms_count_) = realms_count.read();
    if (yes_or_no == 0) {
        let (no_pourcentage, _) = unsigned_div_rem((votes.no + 1) * 100, realms_count_);
        let is_majority_no = is_le(50, no_pourcentage);
        if (is_majority_no == 1) {
            _reset_voting_emperor(
                proposing_realm_id=proposing_realm_id, length=votes.yes + votes.no, index=0
            );
            return ();
        }
        voting_ledger_emperor.write(proposing_realm_id, Votes(votes.yes, votes.no + 1));
        has_voted_emperor.write(proposing_realm_id, realm_id, 1);
        voter_list_emperor.write(proposing_realm_id, votes.yes + votes.no, realm_id);
        return ();
    }
    if (yes_or_no == 1) {
        let (yes_pourcentage, _) = unsigned_div_rem((votes.yes + 1) * 100, realms_count_);
        let is_majority_yes = is_le(50, yes_pourcentage);
        if (is_majority_yes == 1) {
            _reset_voting_emperor(
                proposing_realm_id=proposing_realm_id, length=votes.yes + votes.no, index=0
            );
            let (emperor_candidate_) = emperor_candidate.read(proposing_realm_id);
            Ownable_owner.write(emperor_candidate_);
            return ();
        }
        voting_ledger_emperor.write(proposing_realm_id, Votes(votes.yes + 1, votes.no));
        has_voted_emperor.write(proposing_realm_id, realm_id, 1);
        voter_list_emperor.write(proposing_realm_id, votes.yes + votes.no, realm_id);
        return ();
    }
    return ();
}

// @notice Resets all the voting data related to one proposing_realm_id
// @param proposing_realm_id The id of the realm who made the proposition
// @param length The number of total votes for that proposal
// @param index Starting index
func _reset_voting_emperor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    proposing_realm_id: felt, length: felt, index: felt
) {
    if (length == index) {
        voting_ledger_emperor.write(proposing_realm_id, Votes(0, 0));
        return ();
    }
    let (voting_realm_id) = voter_list_emperor.read(proposing_realm_id, index);
    has_voted_emperor.write(proposing_realm_id, voting_realm_id, 0);
    voter_list_emperor.write(proposing_realm_id, index, 0);
    _reset_voting_emperor(proposing_realm_id=proposing_realm_id, length=length, index=index + 1);
    return ();
}
