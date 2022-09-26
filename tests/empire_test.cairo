%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.hash import hash2
from starkware.starknet.common.syscalls import get_contract_address
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.signature import verify_ecdsa_signature

from contracts.empire import delegate, add_empire_enemy
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
from contracts.empires.internals import hash_array

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
const GAME_CONTRACT = 12345;
const REALM_CONTRACT = 123;
const LORDS_CONTRACT = 123456789;

@contract_interface
namespace IERC721 {
    func mint(to: felt, tokenId: Uint256) {
    }
    func ownerOf(tokenId: Uint256) -> (owner: felt) {
    }
}

@external
func __setup__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    let (local address) = get_contract_address();
    %{ context.self_address = ids.address %}
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
    local address;
    %{
        context.realm_contract_address = deploy_contract("./tests/ERC721/ERC721MintableBurnable.cairo", [0, 0, ids.ACCOUNT]).contract_address 
        stop_prank = start_prank(ids.ACCOUNT, target_contract_address=context.realm_contract_address)
        ids.address = context.realm_contract_address
    %}
    IERC721.mint(contract_address=address, to=ACCOUNT, tokenId=Uint256(1, 0));
    %{ stop_prank() %}
    return ();
}

@external
func test_delegate{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    local address;
    // check an enemy cannot join the empire
    %{
        store(context.self_address, "is_enemy", [1], key=[ids.ACCOUNT]) 
        stop_prank = start_prank(ids.ACCOUNT)
        ids.address = context.self_address
        expect_revert(error_message="lord is an enemy of the empire")
    %}
    delegate(realm_id=1);

    // check a delegate action creates a new realm in the empire and transfers the realm nft to the empire
    %{ store(context.self_address, "is_enemy", [0], key=[ids.ACCOUNT]) %}
    delegate(realm_id=1);
    let (local token_owner) = IERC721.ownerOf(contract_address=address, tokenId=Uint256(1, 0));
    %{
        stop_prank()
        realm = load(context.self_address, "realms", "Realm", key=[1])
        lord = load(context.self_address, "lords", "felt", key=[ids.ACCOUNT])[0]
        assert realm[0] == ids.ACCOUNT, f'lord error, expected {ids.ACCOUNT}, got {realm[0]}'
        assert context.self_address == ids.token_owner, f'token owner error, expected {context.self_address}, got {ids.token_owner}'
        assert lord == 1, f'number of realm in empire error, expected 1, got {lord}'
    %}
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
    let arr_hash = hash_array(data_len=14, data=call_data_arr, hash=0);

    // tx hash
    tempvar tx_hash: felt* = new (INVOKE, VERSION, SENDER, EXECUTE_ENTRYPOINT, arr_hash, MAX_FEE, GOERLI, 7);
    let hash = hash_array(data_len=8, data=tx_hash, hash=0);

    verify_ecdsa_signature(message=hash, public_key=PUBLIC_KEY, signature_r=R, signature_s=S);

    return ();
}
