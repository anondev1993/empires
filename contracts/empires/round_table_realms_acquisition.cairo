%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero, assert_le, unsigned_div_rem, assert_lt
from starkware.cairo.common.math_cmp import is_le
from starkware.starknet.common.syscalls import get_caller_address, get_block_timestamp
from starkware.cairo.common.uint256 import Uint256
from src.openzeppelin.access.ownable.library import Ownable

from contracts.empires.storage import (
    realms,
    acquisition_candidate,
    voting_ledger_acquisition,
    has_voted_acquisition,
    voter_list_acquisition,
    realms_count,
)
from contracts.empires.structures import Votes, Acquisition

// TODO: test these functions

// @notice Starts the voting process to acquire a realm on L1
// @param acquisition The new proposed realm on L1 to be acquired
// @param realm_id The proposing realm
@external
func propose_realm_acquisition{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: felt, eth_amount: felt, realm_id: felt
) {
    let (caller) = get_caller_address();
    let (realm: Realm) = realms.read(realm_id);

    with_attr error_message("calling lord is the zero address") {
        assert_not_zero(caller);
    }
    with_attr error_message("calling lord does not own this realm") {
        assert caller = realm.lord;
    }
    with_attr error_message("price of acquisition needs to be higher than 0") {
        assert_lt(0, eth_amount);
    }

    let (votes: Votes) = voting_ledger_acquisition.read(realm_id);
    _reset_voting_acquisition(proposing_realm_id=realm_id, length=votes.yes + votes.no, index=0);

    let (count) = realms_count.read();

    // if there is only one realm, validate the acquisition
    if (count == 1) {
        let (acquisition_candidate: Acquisition) = Acquisition(token_id, eth_amount, 1);
        acquisition_candidate.write(realm_id, acquisition_candidate);
        return ();
    }
    voting_ledger_acquisition.write(realm_id, Votes(1, 0));
    has_voted_acquisition.write(realm_id, realm_id, 1);
    voter_list_acquisition.write(realm_id, 0, realm_id);
    let (acquisition_candidate: Acquisition) = Acquisition(token_id, eth_amount, 0);
    acquisition_candidate.write(realm_id, acquisition_candidate);
    return ();
}

// @notice Vote yes or no for a proposal
// @param proposing_realm_id The id of the realm who made the proposition
// @param realm_id The id of a realm owned by the caller
// @param yes_or_no The vote for that proposal
@external
func vote_acquisition{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    proposing_realm_id: felt, realm_id: felt, yes_or_no: felt
) {
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

    let (has_voted_acquisition) = has_voted_acquisition.read(proposing_realm_id, realm_id);
    with_attr error_message("realm has already voted") {
        assert has_voted_acquisition = 0;
    }

    let (votes: Votes) = voting_ledger_acquisition.read(proposing_realm_id);
    let (realms_count) = realms_count.read();
    if (yes_or_no == 0) {
        let (no_pourcentage, _) = unsigned_div_rem((votes.no + 1) * 100, realms_count);
        let (is_majority_no) = is_le(50, no_pourcentage);
        if (is_majority_no == 1) {
            _reset_voting_acquisition(
                proposing_realm_id=proposing_realm_id, length=votes.yes + votes.no, index=0
            );
            return ();
        }
        voting_ledger_acquisition.write(proposing_realm_id, Votes(votes.yes, votes.no + 1));
        has_voted_acquisition.write(proposing_realm_id, realm_id, 1);
        voter_list_acquisition.write(proposing_realm_id, votes.yes + votes.no, realm_id);
    }
    if (yes_or_no == 1) {
        let (yes_pourcentage, _) = unsigned_div_rem((votes.yes + 1) * 100, realms_count);
        let (is_majority_yes) = is_le(50, yes_pourcentage);
        if (is_majority_yes == 1) {
            _reset_voting_acquisition(
                proposing_realm_id=proposing_realm_id, length=votes.yes + votes.no, index=0
            );
            let (acquisition_candidate: Acquisition) = acquisition_candidate(proposing_realm_id);
            acquisition_candidate.passed = true;
            Ownable.transfer_ownership(acquisition_candidate);
            return ();
        }
        voting_ledger_acquisition.write(proposing_realm_id, Votes(votes.yes + 1, votes.no));
        has_voted_acquisition.write(proposing_realm_id, realm_id, 1);
        voter_list_acquisition.write(proposing_realm_id, votes.yes + votes.no, realm_id);
    }
    return ();
}

// @notice Resets all the voting data related to one proposing_realm_id
// @param proposing_realm_id The id of the realm who made the proposition
// @param length The number of total votes for that proposal
// @param index Starting index
func _reset_voting_acquisition{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    proposing_realm_id: felt, length: felt, index: felt
) {
    if (length == index) {
        voting_ledger_acquisition.write(realm_id, Votes(0, 0));
        return ();
    }
    let (voting_realm_id) = voter_list_acquisition.read(proposing_realm_id, index);
    has_voted_acquisition.write(proposing_realm_id, voting_realm_id, 0);
    voter_list_acquisition.write(proposing_realm_id, index, 0);
    _reset_voting_acquisition(
        proposing_realm_id=proposing_realm_id, length=length, index=index + 1
    );
    return ();
}