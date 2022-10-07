%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_contract_address

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
    alloc_locals;
    local ETH_AMOUNT = 1;
    local TOKEN_ID = 1;
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
    %}
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
