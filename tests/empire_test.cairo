%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.signature import verify_ecdsa_signature

from contracts.empires.constants import TAX_PRECISION

from contracts.empires.internals import hash_array

const EMPEROR = 123456;
const REALM_CONTRACT = 1234;
const GAME_CONTRACT = 12345;
const LORDS_CONTRACT = 123456789;

func __setup__() {
    return ();
}

@external
func est_deploy{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    %{
        from random import randint
        producer_taxes = randint(1, ids.TAX_PRECISION)
        attacker_taxes = randint(1, ids.TAX_PRECISION)
        goblin_taxes = randint(1, ids.TAX_PRECISION)
        address = deploy_contract("./contracts/empire.cairo", 
                    [ids.EMPEROR, ids.REALM_CONTRACT, ids.GAME_CONTRACT, ids.LORDS_CONTRACT, producer_taxes, attacker_taxes, goblin_taxes]).contract_address
        owner = load(address, "Ownable_owner", "felt")[0]
        add = load(address, "realm_contract", "felt")[0]
        p_taxes = load(address, "producer_taxes", "felt")[0]
        a_taxes = load(address, "attacker_taxes", "felt")[0]
        g_taxes = load(address, "goblin_taxes", "felt")[0]
        assert owner == ids.EMPEROR, f'contract emperor error, expected {ids.EMPEROR}, got {owner}'
        assert add == ids.REALM_CONTRACT, f'contract address error, expected {ids.REALM_CONTRACT}, got {add}'
        assert p_taxes == producer_taxes, f'producer taxes error, expected {producer_taxes}, got {p_taxes}'
        assert a_taxes == attacker_taxes, f'contract emperor error, expected {attacker_taxes}, got {a_taxes}'
        assert g_taxes == goblin_taxes, f'contract emperor error, expected {goblin_taxes}, got {g_taxes}'
    %}
    return ();
}

@external
func test_add_enemy{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, ecdsa_ptr: SignatureBuiltin*
}() {
    alloc_locals;
    let hash_ptr = pedersen_ptr;
    const INVOKE = 115923154332517;
    const SN_GOERLI = 1536727068981429685321;
    const REALMS_CONTRACT = 0x04d0ec084ad44bc3e6bf534cffc7ff939f3aec31e3fb6f5b8056b1fd3c839cb2;
    const SELECTOR = 0x017ede4f49681c9dae848775b4d2f0ed97126948777e787e2f6ad7e2a1313b40;
    const ENTRYPOINT = 0x15d40a3d6ca2ac30f4031e42be28da9b056fef9bb7357ac5e85627ee876e5ad;
    const SENDER = 0x7ff2c85c7b1de1808ddf8897bc729feefa71ba269ea1015d1fd7a18c9918cc3;
    const PUBLIC_KEY = 0x05a3d804471a6dd1c4dd939f420811e61a76908588a2cef583cb7375f78c0592;
    const R = 0x22ba35fb787fa97b63175cf5137b1827609daf483d5ebcaf09d0d61806b232d;
    const S = 0x3f12f5b2b375e1f4e8ef20a02b86f63d4104af6d9a7ba1489a335bb8db34d85;
    const ATTACKING_ARMY_ID = 0x01;
    const ATTACKING_REALM_ID = 0x04d2;
    const DEFENDING_ARMY_ID = 0x00;
    const DEFENDING_REALM_ID = 0x7b;
    const MAX_FEE = 0x46e76abf8;
    const VERSION = 0;
    const NONCE = 0x18;

    // hash calldata
    tempvar call_data_arr: felt* = new (1, REALMS_CONTRACT, SELECTOR, 0, 6, 6, ATTACKING_ARMY_ID, ATTACKING_REALM_ID, 0, DEFENDING_ARMY_ID, DEFENDING_REALM_ID, 0, NONCE, 13);
    let arr_hash = hash_array(data_len=14, data=call_data_arr, hash=0);
    %{ print("HASH ARRAY", ids.arr_hash) %}

    // tx hash
    tempvar tx_hash: felt* = new (INVOKE, VERSION, SENDER, ENTRYPOINT, arr_hash, MAX_FEE, SN_GOERLI, 7);
    let hash = hash_array(data_len=8, data=tx_hash, hash=0);
    %{ print("FINAL HASH", ids.hash) %}

    verify_ecdsa_signature(message=hash, public_key=PUBLIC_KEY, signature_r=R, signature_s=S);

    return ();
}
