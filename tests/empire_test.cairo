%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.hash import hash2
from starkware.starknet.common.syscalls import get_contract_address
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.signature import verify_ecdsa_signature

from contracts.empire import delegate, add_empire_enemy, issue_bounty, hire_mercenary
from contracts.empires.storage import is_enemy, realms, lords
from contracts.empires.structures import Realm
from contracts.empires.constants import (
    TAX_PRECISION,
    INVOKE,
    GOERLI,
    VERSION,
    INITIATE_COMBAT_SELECTOR,
    EXECUTE_ENTRYPOINT,
)
from contracts.empires.internals import _hash_array

from tests.data.add_empire_enemy_data import (
    SENDER,
    REALMS_CONTRACT,
    PUBLIC_KEY,
    R,
    S,
    MAX_FEE,
    NONCE,
    ATTACKING_ARMY_ID,
    DEFENDING_ARMY_ID,
    ATTACKING_REALM_ID,
    DEFENDING_REALM_ID,
)

const EMPEROR = 123456;
const ACCOUNT = 1;
const MERCENARY = 100;
const REALM_MERCENARY = 100;
const TARGET = 101;
const REALM_TARGET = 101;
const AMOUNT = 10000;
const GAME_CONTRACT = 12345;
const REALM_CONTRACT = 123;
const LORDS_CONTRACT = 123456789;

@contract_interface
namespace IERC721 {
    func mint(to: felt, tokenId: Uint256) {
    }
    func ownerOf(tokenId: Uint256) -> (owner: felt) {
    }
    func approve(approved: felt, tokenId: Uint256) {
    }
}

@contract_interface
namespace IERC20 {
    func balanceOf(account: felt) -> (balance: Uint256) {
    }
}

@contract_interface
namespace Account {
    func getSigner() -> (signer: felt) {
    }
    func initialize(signer: felt, guardian: felt) {
    }
}

@external
func __setup__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    let (local address) = get_contract_address();
    %{
        context.self_address = ids.address 
        context.lord_contract = deploy_contract("./tests/ERC20/ERC20Mintable.cairo", [0, 0, 6, ids.AMOUNT, 0, ids.address, ids.address]).contract_address
        context.realm_contract_address = deploy_contract("./tests/ERC721/ERC721MintableBurnable.cairo", [0, 0, ids.ACCOUNT]).contract_address
        store(context.self_address, "realm_contract", [context.realm_contract_address])
        store(context.self_address, "lords_contract", [context.lord_contract])
        store(context.self_address, "Ownable_owner", [ids.EMPEROR])
    %}
    return ();
}

@external
func test_deploy{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    %{
        from random import randint
        producer_taxes = randint(1, ids.TAX_PRECISION)
        attacker_taxes = randint(1, ids.TAX_PRECISION)
        goblin_taxes = randint(1, ids.TAX_PRECISION)
        # deploy the empire contract
        address = deploy_contract("./contracts/empire.cairo", 
                    [ids.EMPEROR, ids.REALM_CONTRACT, ids.GAME_CONTRACT, ids.LORDS_CONTRACT, producer_taxes, attacker_taxes, goblin_taxes]).contract_address
        owner = load(address, "Ownable_owner", "felt")[0]
        add = load(address, "realm_contract", "felt")[0]
        p_taxes = load(address, "producer_taxes", "felt")[0]
        a_taxes = load(address, "attacker_taxes", "felt")[0]
        g_taxes = load(address, "goblin_taxes", "felt")[0]
        # check contract contains deployed information
        assert owner == ids.EMPEROR, f'contract emperor error, expected {ids.EMPEROR}, got {owner}'
        assert add == ids.REALM_CONTRACT, f'contract address error, expected {ids.REALM_CONTRACT}, got {add}'
        assert p_taxes == producer_taxes, f'producer taxes error, expected {producer_taxes}, got {p_taxes}'
        assert a_taxes == attacker_taxes, f'contract emperor error, expected {attacker_taxes}, got {a_taxes}'
        assert g_taxes == goblin_taxes, f'contract emperor error, expected {goblin_taxes}, got {g_taxes}'
    %}
    return ();
}

@external
func setup_delegate{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    local realm_address;
    local address;
    %{
        ids.realm_address = context.realm_contract_address
        ids.address = context.self_address
    %}
    %{ stop_prank = start_prank(ids.ACCOUNT, target_contract_address=ids.realm_address) %}
    IERC721.mint(contract_address=realm_address, to=ACCOUNT, tokenId=Uint256(1, 0));
    IERC721.approve(contract_address=realm_address, approved=address, tokenId=Uint256(1, 0));
    %{ stop_prank() %}
    return ();
}

@external
func test_delegate{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    local address;
    %{
        start_prank(ids.ACCOUNT)
        ids.address = context.realm_contract_address
    %}

    // check a delegate action creates a new realm in the empire and transfers the realm nft to the empire
    delegate(realm_id=1);
    let (local token_owner) = IERC721.ownerOf(contract_address=address, tokenId=Uint256(1, 0));
    %{
        realm = load(context.self_address, "realms", "Realm", key=[1])
        lord = load(context.self_address, "lords", "felt", key=[ids.ACCOUNT])[0]
        assert realm[0] == ids.ACCOUNT, f'lord error, expected {ids.ACCOUNT}, got {realm[0]}'
        assert context.self_address == ids.token_owner, f'token owner error, expected {context.self_address}, got {ids.token_owner}'
        assert lord == 1, f'number of realm in empire error, expected 1, got {lord}'
    %}
    return ();
}

@external
func test_delegate_empire_enemy{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    // check an enemy cannot join the empire
    %{
        store(context.self_address, "is_enemy", [1], key=[ids.ACCOUNT]) 
        start_prank(ids.ACCOUNT)
        expect_revert(error_message="lord is an enemy of the empire")
    %}
    delegate(realm_id=1);
    return ();
}

@external
func test_delegate_zero{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    local address;
    // check revert on zero caller address
    %{
        start_prank(0)
        expect_revert(error_message="caller is the zero address")
    %}
    delegate(realm_id=1);
    return ();
}

@external
func test_verify_ecdsa_signature{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, ecdsa_ptr: SignatureBuiltin*
}() {
    alloc_locals;
    let hash_ptr = pedersen_ptr;

    // hash calldata
    tempvar call_data_arr: felt* = new (1, REALMS_CONTRACT, INITIATE_COMBAT_SELECTOR, 0, 6, 6, ATTACKING_ARMY_ID, ATTACKING_REALM_ID, 0, DEFENDING_ARMY_ID, DEFENDING_REALM_ID, 0, NONCE, 13);
    let arr_hash = _hash_array(data_len=14, data=call_data_arr, hash=0);

    // tx hash
    tempvar tx_hash: felt* = new (INVOKE, VERSION, SENDER, EXECUTE_ENTRYPOINT, arr_hash, MAX_FEE, GOERLI, 7);
    let hash = _hash_array(data_len=8, data=tx_hash, hash=0);

    verify_ecdsa_signature(message=hash, public_key=PUBLIC_KEY, signature_r=R, signature_s=S);

    return ();
}

@external
func test_add_empire_enemy_zero_owner{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, ecdsa_ptr: SignatureBuiltin*
}() {
    %{ expect_revert(error_message="Ownable: caller is the zero address") %}
    add_empire_enemy(0, 0, 0, 0, 0, 0, 0, 0, 0);
    return ();
}

@external
func test_add_empire_enemy_wrong_owner{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, ecdsa_ptr: SignatureBuiltin*
}() {
    %{
        start_prank(ids.ACCOUNT)
        expect_revert(error_message="Ownable: caller is not the owner")
    %}
    add_empire_enemy(0, 0, 0, 0, 0, 0, 0, 0, 0);
    return ();
}

@external
func test_add_empire_enemy_zero_attacker{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, ecdsa_ptr: SignatureBuiltin*
}() {
    %{
        start_prank(ids.EMPEROR)
        expect_revert(error_message="attacker is the zero address")
    %}
    add_empire_enemy(0, 0, 0, 0, 0, 0, 0, 0, 0);
    return ();
}

@external
func test_add_empire_enemy_missing_defender{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, ecdsa_ptr: SignatureBuiltin*
}() {
    %{
        start_prank(ids.EMPEROR)
        expect_revert(error_message="defender not part of the empire")
    %}
    add_empire_enemy(SENDER, 0, 0, 0, 0, 0, 0, 0, 0);
    return ();
}

@external
func setup_add_empire_enemy{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    %{ context.account_address = deploy_contract("./lib/argent_contracts_starknet_git/contracts/account/ArgentAccount.cairo").contract_address %}
    return ();
}

@external
func test_add_empire_enemy{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, ecdsa_ptr: SignatureBuiltin*
}(random: felt) {
    alloc_locals;
    local address;
    local public;
    local private;
    local realm;
    %{
        from starkware.crypto.signature.signature import private_to_stark_key, sign, verify
        ids.private = ids.random % PRIME//2 + 1
        store(context.self_address, "realms", [ids.ACCOUNT, 1, 1], key=[ids.DEFENDING_REALM_ID])
        ids.realm = context.realm_contract_address
        ids.address = context.account_address
        ids.public = private_to_stark_key(ids.private)
    %}
    // generate hash message
    // hash calldata
    tempvar calldata_arr: felt* = new (1, realm, INITIATE_COMBAT_SELECTOR, 0, 6, 6, ATTACKING_ARMY_ID, ATTACKING_REALM_ID, 0, DEFENDING_ARMY_ID, DEFENDING_REALM_ID, 0, NONCE, 13);
    let calldata_hash = _hash_array(data_len=14, data=calldata_arr, hash=0);
    // tx hash
    tempvar tx_hash: felt* = new (INVOKE, VERSION, address, EXECUTE_ENTRYPOINT, calldata_hash, MAX_FEE, GOERLI, 7);
    let hash = _hash_array(data_len=8, data=tx_hash, hash=0);

    // sign the transaction
    local signed_msg;
    local r;
    local s;
    %{
        r, s = sign(ids.hash, ids.private) 
        ids.r = r
        ids.s = s
    %}

    // initialize the argent account
    Account.initialize(contract_address=address, signer=public, guardian=0);
    let (signer) = Account.getSigner(contract_address=address);
    %{ assert ids.public == ids.signer, f'signer error, expected {ids.public}, got {ids.signer}' %}

    // mint token
    %{ start_prank(ids.ACCOUNT, target_contract_address=ids.realm) %}
    IERC721.mint(contract_address=realm, to=address, tokenId=Uint256(ATTACKING_REALM_ID, 0));

    // add the empire's enemy
    %{ start_prank(ids.EMPEROR) %}
    add_empire_enemy(
        address,
        ATTACKING_REALM_ID,
        ATTACKING_ARMY_ID,
        DEFENDING_REALM_ID,
        DEFENDING_ARMY_ID,
        MAX_FEE,
        NONCE,
        r,
        s,
    );
    return ();
}

@external
func test_issue_bounty_revert_zero_address{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    %{ expect_revert(error_message="Ownable: caller is the zero address") %}
    issue_bounty(1, 100);
    return ();
}

@external
func test_issue_bounty_revert_not_emperor{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    %{
        start_prank(ids.ACCOUNT)
        expect_revert(error_message="Ownable: caller is not the owner")
    %}
    issue_bounty(1, 100);
    return ();
}

@external
func test_issue_bounty{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    %{ start_prank(ids.EMPEROR) %}
    const enemy_realm_id = 1;
    const BOUNTY = 100;
    issue_bounty(enemy_realm_id, BOUNTY);
    %{
        bounty = load(context.self_address, "bounties", "felt", key=[ids.enemy_realm_id])[0]
        assert ids.BOUNTY == bounty, f'bounty error, expected {ids.BOUNTY}, got {bounty}'
    %}
    return ();
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
    func set_combat_outcome(_outcome: felt) {
    }
}

@external
func setup_hire_mercenary{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    local realm_contract_address;
    local address;
    %{
        from random import randint
        context.amount_bounty = 100;

        context.game_contract_address = deploy_contract("./tests/Combat/Combat.cairo", [0]).contract_address
        store(context.self_address, "bounties", [context.amount_bounty], key=[ids.REALM_TARGET])
        store(context.self_address, "game_contract", [context.game_contract_address])
        ids.realm_contract_address = context.realm_contract_address
        ids.address = context.self_address
        stop_prank = start_prank(ids.ACCOUNT, target_contract_address=ids.realm_contract_address)
    %}
    IERC721.mint(
        contract_address=realm_contract_address, to=MERCENARY, tokenId=Uint256(REALM_MERCENARY, 0)
    );
    %{
        stop_prank()
        stop_prank = start_prank(ids.MERCENARY, target_contract_address=ids.realm_contract_address)
    %}
    IERC721.approve(
        contract_address=realm_contract_address,
        approved=address,
        tokenId=Uint256(REALM_MERCENARY, 0),
    );
    %{ stop_prank() %}
    return ();
}

@external
func test_hire_mercenary{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    local realm_contract_address;
    local game_contract_address;
    local lord_contract_address;
    local address;
    %{
        start_prank(ids.MERCENARY, target_contract_address=context.self_address) 
        ids.realm_contract_address = context.realm_contract_address
        ids.game_contract_address = context.game_contract_address
        ids.lord_contract_address = context.lord_contract
        ids.address = context.self_address
    %}
    // outcome = 0
    ICombat.set_combat_outcome(contract_address=game_contract_address, _outcome=0);
    hire_mercenary(
        target_realm_id=REALM_TARGET, attacking_realm_id=REALM_MERCENARY, attacking_army_id=1
    );
    let (balance: Uint256) = IERC20.balanceOf(
        contract_address=lord_contract_address, account=MERCENARY
    );
    let (owner) = IERC721.ownerOf(
        contract_address=realm_contract_address, tokenId=Uint256(REALM_MERCENARY, 0)
    );
    %{
        assert ids.balance.low == 0, f'mercenary balance error, expected 0, got {ids.balance.low}' 
        bounty = load(context.self_address, "bounties", "felt", key=[ids.REALM_TARGET])[0]
        assert bounty == context.amount_bounty, f'bounty error, expected {context.amount_bounty}, got {bounty}'
        assert ids.owner == ids.MERCENARY, f'realm owner error, expected {ids.MERCENARY}, got {owner}'
    %}

    // outcome = 1
    %{ stop_prank = start_prank(ids.MERCENARY, target_contract_address=context.realm_contract_address) %}
    IERC721.approve(
        contract_address=realm_contract_address,
        approved=address,
        tokenId=Uint256(REALM_MERCENARY, 0),
    );
    %{ stop_prank() %}
    ICombat.set_combat_outcome(contract_address=game_contract_address, _outcome=1);
    hire_mercenary(
        target_realm_id=REALM_TARGET, attacking_realm_id=REALM_MERCENARY, attacking_army_id=1
    );
    let (balance: Uint256) = IERC20.balanceOf(
        contract_address=lord_contract_address, account=MERCENARY
    );
    let (owner) = IERC721.ownerOf(
        contract_address=realm_contract_address, tokenId=Uint256(REALM_MERCENARY, 0)
    );
    %{
        assert ids.balance.low == context.amount_bounty, f'mercenary balance error, expected {context.amount_bounty}, got {ids.balance.low}' 
        bounty = load(context.self_address, "bounties", "felt", key=[ids.REALM_TARGET])[0]
        assert bounty == 0, f'bounty error, expected 0, got {bounty}'
        assert ids.owner == ids.MERCENARY, f'realm owner error, expected {ids.MERCENARY}, got {owner}'
    %}
    return ();
}
