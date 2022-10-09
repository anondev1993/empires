%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_contract_address
from starkware.cairo.common.alloc import alloc

from contracts.empires.round_table_realms_acquisition import (
    propose_realm_acquisition,
    vote_acquisition,
    _reset_voting_acquisition,
)

const EMPEROR = 123456;
const ACCOUNT = 1;
const REALM_QUANTITY = 15;
const VOTING_REALM = 123;
const PROPOSING_REALM = 1234;
const ETH_AMOUNT = 1409184492184;
const TOKEN_ID = 609;

@external
func __setup__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    let (local address) = get_contract_address();
    %{ context.self_address = ids.address %}
    return ();
}

@external
func test_propose_realm_acquisition_zero{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    %{
        start_prank(0) 
        expect_revert(error_message="calling lord is the zero address")
    %}
    propose_realm_acquisition(token_id=1, eth_amount=1, realm_id=1);
    return ();
}

@external
func test_propose_realm_acquisition_not_owned{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    %{
        start_prank(ids.ACCOUNT) 
        expect_revert(error_message="calling lord does not own this realm")
    %}
    propose_realm_acquisition(token_id=1, eth_amount=1, realm_id=1);
    return ();
}

@external
func test_propose_realm_acquisition_incorrect_price{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    %{
        start_prank(ids.ACCOUNT) 
        store(context.self_address, "realms", [ids.ACCOUNT, 1, 0, 0], key=[ids.PROPOSING_REALM])
        expect_revert(error_message="price of acquisition needs to be higher than 0")
    %}
    propose_realm_acquisition(token_id=1, eth_amount=0, realm_id=PROPOSING_REALM);
    return ();
}

@external
func test_propose_realm_acquisition_one_realm{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    local ETH_AMOUNT = 1;
    local TOKEN_ID = 1;
    %{
        start_prank(ids.ACCOUNT) 
        store(context.self_address, "realms", [ids.ACCOUNT, 1, 0, 0], key=[ids.PROPOSING_REALM])
        store(context.self_address, "realms_count", [1])
    %}
    propose_realm_acquisition(token_id=TOKEN_ID, eth_amount=ETH_AMOUNT, realm_id=PROPOSING_REALM);
    %{
        acquisition = load(context.self_address, "acquisition_candidate", "Acquisition", key=[ids.PROPOSING_REALM])
        assert acquisition[0] == ids.TOKEN_ID, f'token id error, expected {ids.TOKEN_ID}, got {acquisition[0]}'
        assert acquisition[1] == ids.ETH_AMOUNT, f'eth amount error, expected {ids.ETH_AMOUNT}, got {acquisition[1]}'
        assert acquisition[2] == 1, f'status error, expected 1, got {acquisition[2]}'
    %}
    return ();
}

@external
func test_propose_realm_acquisition{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    %{
        start_prank(ids.ACCOUNT) 
        store(context.self_address, "realms", [ids.ACCOUNT, 1, 0, 0], key=[ids.PROPOSING_REALM])
        store(context.self_address, "realms_count", [2])
    %}
    propose_realm_acquisition(token_id=TOKEN_ID, eth_amount=ETH_AMOUNT, realm_id=PROPOSING_REALM);
    %{
        ledger = load(context.self_address, "voting_ledger_acquisition", "Votes", key=[ids.PROPOSING_REALM])
        realm_id = load(context.self_address, "voter_list_acquisition", "felt", key=[ids.PROPOSING_REALM, 0])[0]
        voted = load(context.self_address, "has_voted_acquisition", "felt", key=[ids.PROPOSING_REALM, ids.PROPOSING_REALM])[0]
        acquisition = load(context.self_address, "acquisition_candidate", "Acquisition", key=[ids.PROPOSING_REALM])
        assert ledger[0] == 1 and ledger[1] == 0, f'ledger error, expected (1,0), got {ledger[0], ledger[1]}'
        assert realm_id == ids.PROPOSING_REALM, f'realm id error, expected {ids.PROPOSING_REALM}, got {realm_id}'
        assert voted == 1, f'voted error, expected 1, got {voted}'
        assert acquisition[0] == ids.TOKEN_ID, f'token id error, expected {ids.TOKEN_ID}, got {acquisition[0]}'
        assert acquisition[1] == ids.ETH_AMOUNT, f'eth amount error, expected {ids.ETH_AMOUNT}, got {acquisition[1]}'
        assert acquisition[2] == 0, f'status error, expected 0, got {acquisition[2]}'
    %}
    return ();
}

@external
func test_vote_acquisition_zero{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    %{
        start_prank(0) 
        expect_revert(error_message="calling lord is the zero address")
    %}
    vote_acquisition(proposing_realm_id=1, realm_id=1, yes_or_no=1);
    return ();
}

@external
func test_vote_acquisition_not_owned{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    %{
        start_prank(ids.ACCOUNT) 
        expect_revert(error_message="calling lord does not own this realm")
    %}
    vote_acquisition(proposing_realm_id=1, realm_id=1, yes_or_no=1);
    return ();
}

@external
func test_vote_acquisition_invalid_vote{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    %{
        start_prank(ids.ACCOUNT) 
        store(context.self_address, "realms", [ids.ACCOUNT, 1, 0, 0], key=[ids.VOTING_REALM])
        expect_revert(error_message="invalid vote")
    %}
    vote_acquisition(proposing_realm_id=PROPOSING_REALM, realm_id=VOTING_REALM, yes_or_no=2);
    return ();
}

@external
func test_vote_acquisition_invalid_acquisition{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    %{
        start_prank(ids.ACCOUNT) 
        store(context.self_address, "realms", [ids.ACCOUNT, 1, 0, 0], key=[ids.VOTING_REALM])
        store(context.self_address, "acquisition_candidate", [ids.TOKEN_ID, ids.ETH_AMOUNT, 1], key=[ids.PROPOSING_REALM])
        expect_revert(error_message="acquisition already passed")
    %}
    vote_acquisition(proposing_realm_id=PROPOSING_REALM, realm_id=VOTING_REALM, yes_or_no=1);
    return ();
}

@external
func test_vote_acquisition_has_voted{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    %{
        start_prank(ids.ACCOUNT) 
        store(context.self_address, "has_voted_acquisition", [1], key=[ids.PROPOSING_REALM, ids.VOTING_REALM])
        store(context.self_address, "realms", [ids.ACCOUNT, 1, 0, 0], key=[ids.VOTING_REALM])
        expect_revert(error_message="realm has already voted")
    %}
    vote_acquisition(proposing_realm_id=PROPOSING_REALM, realm_id=VOTING_REALM, yes_or_no=1);
    return ();
}

@external
func test_vote_acquisition_no_minority{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    local length;
    %{
        store(context.self_address, "realms", [ids.ACCOUNT, 1, 0, 0], key=[ids.VOTING_REALM])
        start_prank(ids.ACCOUNT) 

        from random import randint
        ids.length = ids.REALM_QUANTITY - 1
        voting_realms = [randint(1, 10000) for i in range(ids.length)]
        yes = ids.length//2 + 1
        no = ids.length - yes
        for i in range(ids.length):
            store(context.self_address, "voter_list_acquisition", [voting_realms[i]], key=[ids.PROPOSING_REALM, i])
            store(context.self_address, "has_voted_acquisition", [1], key=[ids.PROPOSING_REALM, voting_realms[i]])
        store(context.self_address, "voting_ledger_acquisition", [yes, no], key=[ids.PROPOSING_REALM])
        store(context.self_address, "realms_count", [ids.REALM_QUANTITY])
    %}
    vote_acquisition(proposing_realm_id=PROPOSING_REALM, realm_id=VOTING_REALM, yes_or_no=0);
    %{
        ledger = load(context.self_address, "voting_ledger_acquisition", "Votes", key=[ids.PROPOSING_REALM])
        assert ledger[0] == yes and ledger[1] == no + 1, f'ledger error, expected {yes, no+1}, got {ledger[0], ledger[1]}'
        realm_id = load(context.self_address, "voter_list_acquisition", "felt", key=[ids.PROPOSING_REALM, yes+no])[0]
        voted = load(context.self_address, "has_voted_acquisition", "felt", key=[ids.PROPOSING_REALM, ids.VOTING_REALM])[0]
        assert realm_id == ids.VOTING_REALM, f'realm id error, expected {ids.VOTING_REALM}, got {realm_id}'
        assert voted == 1, f'voted error, expected 1, got {voted}'
    %}
    return ();
}

@external
func test_vote_acquisition_no_majority{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    local length;
    %{
        store(context.self_address, "realms", [ids.ACCOUNT, 1, 0, 0], key=[ids.VOTING_REALM])
        start_prank(ids.ACCOUNT) 

        from random import randint
        ids.length = ids.REALM_QUANTITY - 1
        voting_realms = [randint(1, 10000) for i in range(ids.length)]
        no = ids.length//2 + 1
        yes = ids.length - no
        for i in range(ids.length):
            store(context.self_address, "voter_list_acquisition", [voting_realms[i]], key=[ids.PROPOSING_REALM, i])
            store(context.self_address, "has_voted_acquisition", [1], key=[ids.PROPOSING_REALM, voting_realms[i]])
        store(context.self_address, "voting_ledger_acquisition", [yes, no], key=[ids.PROPOSING_REALM])
        store(context.self_address, "realms_count", [ids.REALM_QUANTITY])
    %}
    vote_acquisition(proposing_realm_id=PROPOSING_REALM, realm_id=VOTING_REALM, yes_or_no=0);
    %{
        ledger = load(context.self_address, "voting_ledger_acquisition", "Votes", key=[ids.PROPOSING_REALM])
        assert ledger[0] == 0 and ledger[1] == 0, f'ledger error, expected (0,0), got {ledger[0], ledger[1]}'
        for i in range(ids.length):
            realm_id = load(context.self_address, "voter_list_acquisition", "felt", key=[ids.PROPOSING_REALM, i])[0]
            voted = load(context.self_address, "has_voted_acquisition", "felt", key=[ids.PROPOSING_REALM, voting_realms[i]])[0]
            assert realm_id == 0, f'realm id error, expected 0, got {realm_id}'
            assert voted == 0, f'voted error, expected 0, got {voted}'
    %}
    return ();
}

@external
func test_vote_acquisition_yes_minority{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    local length;
    %{
        store(context.self_address, "realms", [ids.ACCOUNT, 1, 0, 0], key=[ids.VOTING_REALM])
        start_prank(ids.ACCOUNT) 

        from random import randint
        ids.length = ids.REALM_QUANTITY - 1
        voting_realms = [randint(1, 10000) for i in range(ids.length)]
        no = ids.length//2 + 1
        yes = ids.length - no
        for i in range(ids.length):
            store(context.self_address, "voter_list_acquisition", [voting_realms[i]], key=[ids.PROPOSING_REALM, i])
            store(context.self_address, "has_voted_acquisition", [1], key=[ids.PROPOSING_REALM, voting_realms[i]])
        store(context.self_address, "voting_ledger_acquisition", [yes, no], key=[ids.PROPOSING_REALM])
        store(context.self_address, "realms_count", [ids.REALM_QUANTITY])
    %}
    vote_acquisition(proposing_realm_id=PROPOSING_REALM, realm_id=VOTING_REALM, yes_or_no=1);
    %{
        ledger = load(context.self_address, "voting_ledger_acquisition", "Votes", key=[ids.PROPOSING_REALM])
        assert ledger[0] == yes+1 and ledger[1] == no, f'ledger error, expected {yes+1, no}, got {ledger[0], ledger[1]}'
        realm_id = load(context.self_address, "voter_list_acquisition", "felt", key=[ids.PROPOSING_REALM, yes+no])[0]
        voted = load(context.self_address, "has_voted_acquisition", "felt", key=[ids.PROPOSING_REALM, ids.VOTING_REALM])[0]
        assert realm_id == ids.VOTING_REALM, f'realm id error, expected {ids.VOTING_REALM}, got {realm_id}'
        assert voted == 1, f'voted error, expected 1, got {voted}'
    %}
    return ();
}

@external
func test_vote_acquisition_yes_majority{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    local length;
    %{
        store(context.self_address, "realms", [ids.ACCOUNT, 1, 0, 0], key=[ids.VOTING_REALM])
        start_prank(ids.ACCOUNT) 

        from random import randint
        ids.length = ids.REALM_QUANTITY - 1
        voting_realms = [randint(1, 10000) for i in range(ids.length)]
        yes = ids.length//2 + 1
        no = ids.length - yes
        for i in range(ids.length):
            store(context.self_address, "voter_list_acquisition", [voting_realms[i]], key=[ids.PROPOSING_REALM, i])
            store(context.self_address, "has_voted_acquisition", [1], key=[ids.PROPOSING_REALM, voting_realms[i]])
        store(context.self_address, "voting_ledger_acquisition", [yes, no], key=[ids.PROPOSING_REALM])
        store(context.self_address, "realms_count", [ids.REALM_QUANTITY])
        store(context.self_address, "acquisition_candidate", [ids.TOKEN_ID, ids.ETH_AMOUNT, 0], key=[ids.PROPOSING_REALM])
    %}
    vote_acquisition(proposing_realm_id=PROPOSING_REALM, realm_id=VOTING_REALM, yes_or_no=1);
    %{
        ledger = load(context.self_address, "voting_ledger_acquisition", "Votes", key=[ids.PROPOSING_REALM])
        assert ledger[0] == 0 and ledger[1] == 0, f'ledger error, expected (0,0), got {ledger[0], ledger[1]}'
        for i in range(ids.length):
            realm_id = load(context.self_address, "voter_list_acquisition", "felt", key=[ids.PROPOSING_REALM, i])[0]
            voted = load(context.self_address, "has_voted_acquisition", "felt", key=[ids.PROPOSING_REALM, voting_realms[i]])[0]
            assert realm_id == 0, f'realm id error, expected 0, got {realm_id}'
            assert voted == 0, f'voted error, expected 0, got {voted}'
        acquisition = load(context.self_address, "acquisition_candidate", "Acquisition", key=[ids.PROPOSING_REALM])
        assert acquisition[0] == ids.TOKEN_ID, f'token id error, expected {ids.TOKEN_ID}, got {acquisition[0]}'
        assert acquisition[1] == ids.ETH_AMOUNT, f'eth amount error, expected {ids.ETH_AMOUNT}, got {acquisition[1]}'
        assert acquisition[2] == 1, f'status error, expected 1, got {acquisition[2]}'
    %}
    return ();
}

@external
func test_integration{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    random: felt
) {
    alloc_locals;
    let (local voting_realms) = alloc();
    let (local owners) = alloc();
    let (local votes) = alloc();
    local length;
    %{
        from random import randint, seed, sample
        seed(ids.random)
        length = ids.REALM_QUANTITY
        voting_realms = [i for i in sample(range(1, 10000), length)]
        owners = [randint(1, 10000) for i in range(length)]
        votes = [randint(0, 1) for i in range(length)]
        j = 0
        result_yes = 1
        result_no = 0
        for i in range(length):
            store(context.self_address, "realms", [owners[i], 1, 0, 0], key=[voting_realms[i]])
            memory[ids.voting_realms + i] = voting_realms[i]
            memory[ids.owners + i] = owners[i]
            memory[ids.votes + i] = votes[i]
            if votes[i]: result_yes += 1
            else: result_no += 1
            if result_yes * 100 // length > 50: 
                j = i + 1
                break
            if result_no * 100 // length > 50: 
                j = i + 1
                break
        store(context.self_address, "realms", [ids.ACCOUNT, 1, 0, 0], key=[ids.PROPOSING_REALM])
        store(context.self_address, "realms_count", [length])
        stop_prank = start_prank(ids.ACCOUNT)
        ids.length = j
    %}
    propose_realm_acquisition(token_id=TOKEN_ID, eth_amount=ETH_AMOUNT, realm_id=PROPOSING_REALM);
    %{ stop_prank() %}
    loop_voting(
        owners_len=length,
        owners=owners,
        realms_len=length,
        realms=voting_realms,
        votes_len=length,
        votes=votes,
        proposing_realm_id=PROPOSING_REALM,
    );
    %{
        ledger = load(context.self_address, "voting_ledger_acquisition", "Votes", key=[ids.PROPOSING_REALM])
        acquisition = load(context.self_address, "acquisition_candidate", "Acquisition", key=[ids.PROPOSING_REALM])
        if result_yes * 100 // length > 50 or result_no * 100 // length > 50:
            assert ledger[0] == 0 and ledger[1] == 0, f'ledger error, expected (0, 0), got {ledger[0], ledger[1]}'
            for i in range(ids.length):
                realm_id = load(context.self_address, "voter_list_acquisition", "felt", key=[ids.PROPOSING_REALM, i])[0]
                voted = load(context.self_address, "has_voted_acquisition", "felt", key=[ids.PROPOSING_REALM, voting_realms[i]])[0]
                assert realm_id == 0, f'realm id error, expected 0, got {realm_id}'
                assert voted == 0, f'voted error, expected 0, got {voted}'
            acq = 0 if result_no * 100 // length > 50 else 1 
            assert acquisition[2] == acq, f'status error, expected {acq}, got {acquisition[2]}'
        else:
            assert ledger[0] == result_yes and ledger[1] == ids.length-result_yes, f'ledger error, expected {result_yes, ids.length-result_yes}, got {ledger[0], ledger[1]}'
            for i in range(ids.length):
                realm_id = load(context.self_address, "voter_list_acquisition", "felt", key=[ids.PROPOSING_REALM, i])[0]
                voted = load(context.self_address, "has_voted_acquisition", "felt", key=[ids.PROPOSING_REALM, voting_realms[i]])[0]
                assert realm_id == voting_realms[i], f'realm id error, expected {voting_realms[i]}, got {realm_id}'
                assert voted == 1, f'voted error, expected 1, got {voted}'
            assert acquisition[2] == 1, f'status error, expected 1, got {acquisition[2]}'
        assert acquisition[0] == ids.TOKEN_ID, f'token id error, expected {ids.TOKEN_ID}, got {acquisition[0]}'
        assert acquisition[1] == ids.ETH_AMOUNT, f'eth amount error, expected {ids.ETH_AMOUNT}, got {acquisition[1]}'
    %}
    return ();
}

@external
func loop_voting{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owners_len: felt,
    owners: felt*,
    realms_len: felt,
    realms: felt*,
    votes_len: felt,
    votes: felt*,
    proposing_realm_id: felt,
) {
    if (votes_len == 0) {
        return ();
    }
    %{ stop_prank = start_prank(memory[ids.owners]) %}
    vote_acquisition(proposing_realm_id=proposing_realm_id, realm_id=[realms], yes_or_no=[votes]);
    %{ stop_prank() %}
    loop_voting(
        owners_len=owners_len - 1,
        owners=owners + 1,
        realms_len=realms_len - 1,
        realms=realms + 1,
        votes_len=votes_len - 1,
        votes=votes + 1,
        proposing_realm_id=proposing_realm_id,
    );
    return ();
}

@external
func test_reset_voting_acquisition{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    ) {
    alloc_locals;
    local random = 10;
    local length;
    %{
        from random import randint
        ids.length = ids.random % ids.REALM_QUANTITY + 1; 
        voting_realms = [randint(1, 10000) for i in range(ids.length)]
        yes = randint(0, ids.length)
        for i in range(ids.length):
            store(context.self_address, "voter_list_acquisition", [voting_realms[i]], key=[ids.PROPOSING_REALM, i])
            store(context.self_address, "has_voted_acquisition", [1], key=[ids.PROPOSING_REALM, voting_realms[i]])
        store(context.self_address, "voting_ledger_acquisition", [yes, ids.length - yes], key=[ids.PROPOSING_REALM])
    %}
    _reset_voting_acquisition(proposing_realm_id=PROPOSING_REALM, length=length, index=0);
    %{
        ledger = load(context.self_address, "voting_ledger_acquisition", "Votes", key=[ids.PROPOSING_REALM])
        assert ledger[0] == 0 and ledger[1] == 0, f'ledger error, expected (0,0), got {ledger[0], ledger[1]}'
        for i in range(ids.length):
            realm_id = load(context.self_address, "voter_list_acquisition", "felt", key=[ids.PROPOSING_REALM, i])[0]
            voted = load(context.self_address, "has_voted_acquisition", "felt", key=[ids.PROPOSING_REALM, voting_realms[i]])[0]
            assert realm_id == 0, f'realm id error, expected 0, got {realm_id}'
            assert voted == 0, f'voted error, expected 0, got {voted}'
    %}
    return ();
}
