%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.math import assert_not_zero, assert_le
from starkware.starknet.common.syscalls import (
    get_caller_address,
    get_contract_address,
    get_block_timestamp,
)
from starkware.cairo.common.signature import verify_ecdsa_signature
from starkware.cairo.common.uint256 import Uint256, uint256_le, uint256_check

from contracts.empires.constants import (
    EXECUTE_ENTRYPOINT,
    GOERLI,
    INITIATE_COMBAT_SELECTOR,
    INVOKE,
    VERSION,
)
from contracts.empires.internals import (
    _hash_array,
    _check_empire_funds,
    swap_lords_for_exact_eth,
    message_l1_acquire_realm,
)
from contracts.empires.storage import (
    eth_contract,
    router_contract,
    l1_empire_contract,
    token_bridge_contract,
    realms,
    lords,
    realms_count,
    realm_contract,
    lords_contract,
    building_module,
    food_module,
    goblin_town_module,
    resource_module,
    travel_module,
    combat_module,
    producer_taxes,
    attacker_taxes,
    goblin_taxes,
    is_enemy,
    bounties,
    acquisition_candidate,
)
from contracts.empires.structures import Realm, Acquisition
from contracts.settling_game.utils.constants import CCombat
from src.openzeppelin.token.erc721.IERC721 import IERC721
from src.openzeppelin.token.erc20.IERC20 import IERC20
from contracts.interfaces.account import Account
from contracts.interfaces.combat import Combat
from contracts.interfaces.token_bridge import ITokenBridge
from src.openzeppelin.access.ownable.library import Ownable

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    emperor: felt,
    realm_contract_address: felt,
    building_module_: felt,
    food_module_: felt,
    goblin_town_module_: felt,
    resource_module_: felt,
    travel_module_: felt,
    combat_module_: felt,
    lords_contract_address: felt,
    eth_contract_address: felt,
    router_contract_address: felt,
    l1_empire_contract_address: felt,
    token_bridge_contract_address: felt,
    producer_taxes_: felt,
    attacker_taxes_: felt,
    goblin_taxes_: felt,
) {
    Ownable.initializer(emperor);
    realm_contract.write(realm_contract_address);
    building_module.write(building_module_);
    food_module.write(food_module_);
    goblin_town_module.write(goblin_town_module_);
    resource_module.write(resource_module_);
    travel_module.write(travel_module_);
    combat_module.write(combat_module_);
    lords_contract.write(lords_contract_address);
    eth_contract.write(eth_contract_address);
    router_contract.write(router_contract_address);
    l1_empire_contract.write(l1_empire_contract_address);
    token_bridge_contract.write(token_bridge_contract_address);
    producer_taxes.write(producer_taxes_);
    attacker_taxes.write(attacker_taxes_);
    goblin_taxes.write(goblin_taxes_);
    return ();
}

// @notice Delegates the realm to the empire
// @param realm_id The realm id to delegate
@external
func delegate{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(realm_id: felt) {
    let (caller) = get_caller_address();
    with_attr error_message("caller is the zero address") {
        assert_not_zero(caller);
    }

    let (_is_enemy) = is_enemy.read(caller);
    with_attr error_message("lord is an enemy of the empire") {
        assert _is_enemy = 0;
    }

    let (empire) = get_contract_address();
    let (realm_contract_address) = realm_contract.read();

    IERC721.transferFrom(
        contract_address=realm_contract_address,
        from_=caller,
        to=empire,
        tokenId=Uint256(realm_id, 0),
    );

    let (ts) = get_block_timestamp();
    realms.write(realm_id, Realm(caller, ts, 0, ts));

    // store empire information
    let (lands) = lords.read(caller);
    lords.write(caller, lands + 1);
    let (count) = realms_count.read();
    realms_count.write(count + 1);
    return ();
}

// @notice Starts the release period for the delegated realm
// @param realm_id The id of the exiting realm
@external
func start_release_period{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    realm_id: felt
) {
    let (caller) = get_caller_address();
    let (realm: Realm) = realms.read(realm_id);

    with_attr error_message("calling lord is the zero address") {
        assert_not_zero(caller);
    }
    with_attr error_message("calling lord does not own this realm") {
        assert caller = realm.lord;
    }
    with_attr error_message("realm already on release period") {
        assert realm.exiting = 0;
    }

    let (ts) = get_block_timestamp();
    realms.write(
        realm_id, Realm(realm.lord, realm.annexation_date, 1, release_date=ts + 24 * 3600)
    );

    return ();
}

// @notice Allows the realm to leave the empire if it has done its release period
// @param realm_id The id of the leaving realm
@external
func leave_empire{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(realm_id: felt) {
    let (caller) = get_caller_address();
    let (realm: Realm) = realms.read(realm_id);

    with_attr error_message("calling lord is the zero address") {
        assert_not_zero(caller);
    }
    with_attr error_message("calling lord does not own this realm") {
        assert caller = realm.lord;
    }
    with_attr error_message("realm not on release period") {
        assert realm.exiting = 1;
    }
    let (ts) = get_block_timestamp();
    with_attr error_message("release period not completed") {
        assert_le(realm.release_date, ts);
    }

    let (empire) = get_contract_address();
    let (realm_contract_address) = realm_contract.read();

    IERC721.transferFrom(
        contract_address=realm_contract_address,
        from_=empire,
        to=caller,
        tokenId=Uint256(realm_id, 0),
    );

    realms.write(realm_id, Realm(0, 0, 0, 0));
    let (lands) = lords.read(caller);
    lords.write(caller, lands - 1);
    let (count) = realms_count.read();
    realms_count.write(count - 1);

    return ();
}

// @notice add a realm as an enemy of the empire
// @dev this function will check that an init_combat transaction
// @dev was created by another realm owner on a realm of the empire
// @param attacker The owner of the attacker realm
// @param attacking_realm_id The id of the attacking realm
// @param attacking_army_id The id of the attacking army
// @param defending_realm_id The id of the defending realm
// @param defending_army_id The id of the defending army
// @param max_fee The max fee used for the attack transaction
// @param nonce The nonce used for the attack transaction
// @param r The x coordinate of the attack transaction signature
// @param s The y coordinate of the attack transaction signature
@external
func add_empire_enemy{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, ecdsa_ptr: SignatureBuiltin*
}(
    attacker: felt,
    attacking_realm_id: felt,
    attacking_army_id: felt,
    defending_realm_id: felt,
    defending_army_id: felt,
    max_fee: felt,
    nonce: felt,
    r: felt,
    s: felt,
) {
    alloc_locals;
    Ownable.assert_only_owner();
    with_attr error_message("attacker is the zero address") {
        assert_not_zero(attacker);
    }

    let (realm) = realms.read(defending_realm_id);
    with_attr error_message("defender not part of the empire") {
        assert_not_zero(realm.lord);
        assert_not_zero(realm.annexation_date);
    }

    let (local realm_contract_address) = realm_contract.read();

    // hash calldata
    tempvar calldata_arr: felt* = new (1, realm_contract_address, INITIATE_COMBAT_SELECTOR, 0, 6, 6, attacking_army_id, attacking_realm_id, 0, defending_army_id, defending_realm_id, 0, nonce, 13);
    let calldata_hash = _hash_array(data_len=14, data=calldata_arr, hash=0);

    // tx hash
    tempvar tx_hash: felt* = new (INVOKE, VERSION, attacker, EXECUTE_ENTRYPOINT, calldata_hash, max_fee, GOERLI, 7);
    let hash = _hash_array(data_len=8, data=tx_hash, hash=0);

    // get attacker public key
    let (pub) = Account.getSigner(contract_address=attacker);
    verify_ecdsa_signature(message=hash, public_key=pub, signature_r=r, signature_s=s);

    // check attacker possesses attacking realm id
    let (owner) = IERC721.ownerOf(
        contract_address=realm_contract_address, tokenId=Uint256(attacking_realm_id, 0)
    );
    assert owner = attacker;

    // add attacker as an enemy
    is_enemy.write(attacking_realm_id, 1);
    return ();
}

// @notice Issues an bounty on the designated realm
// @param enemy_realm_id The enemy realm id
// @param amount The amount of $LORDS used for the bounty
@external
func issue_bounty{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    enemy_realm_id: felt, amount: felt
) {
    Ownable.assert_only_owner();
    _check_empire_funds(amount);
    bounties.write(enemy_realm_id, amount);
    return ();
}

// @notice Claim the bounty on the target realm by performing combat on the
// @notice enemy realm
// @dev The attacking realm must have approved the empire contract before
// @dev calling hire_mercenary
// @param target_realm_id The target realm for the attack
// @param attacking_realm_id The id of the attacking realm
// @param attacking_army_id The id of the attacking army
@external
func hire_mercenary{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    target_realm_id: felt, attacking_realm_id: felt, attacking_army_id: felt
) -> () {
    alloc_locals;
    let (bounty) = bounties.read(target_realm_id);
    with_attr error_message("no bounty on target realm {target_realm_id}") {
        assert_not_zero(bounty);
    }
    _check_empire_funds(bounty);

    let (caller) = get_caller_address();
    let (empire) = get_contract_address();
    let (local realm_contract_address) = realm_contract.read();
    let (lords_contract_address) = lords_contract.read();

    // temporarily transfer the command of the armies of the mercenary to the empire
    IERC721.transferFrom(
        contract_address=realm_contract_address,
        from_=caller,
        to=empire,
        tokenId=Uint256(attacking_realm_id, 0),
    );

    // attack the target of the bounty
    let (combat_module_) = combat_module.read();
    let (result) = Combat.initiate_combat(
        contract_address=combat_module_,
        attacking_army_id=attacking_army_id,
        attacking_realm_id=Uint256(attacking_realm_id, 0),
        defending_army_id=0,
        defending_realm_id=Uint256(target_realm_id, 0),
    );

    // reward the bounty and return the armies of the attacking realm
    if (result == CCombat.COMBAT_OUTCOME_ATTACKER_WINS) {
        IERC20.transfer(
            contract_address=lords_contract_address, recipient=caller, amount=Uint256(bounty, 0)
        );
        bounties.write(target_realm_id, 0);
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    } else {
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }

    IERC721.transferFrom(
        contract_address=realm_contract_address,
        from_=empire,
        to=caller,
        tokenId=Uint256(attacking_realm_id, 0),
    );

    return ();
}

// @notice swaps token and sends them to L1 with a message approving buying a realm on OpenSea
// @param max_lords_amount Maximum number of lords token to swap to get an exact eth amount
// @param proposing_realm_id Id of the realm who made a proposition that has been passed
@external
func acquire_realm_l1{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    max_lords_amount: Uint256, proposing_realm_id: felt
) -> () {
    alloc_locals;
    // check that the caller is the emperor
    Ownable.assert_only_owner();

    // check that the realm to be acquired has been voted by the lords
    let (acquisition: Acquisition) = acquisition_candidate.read(proposing_realm_id);

    with_attr error_message("realm acquisition has not been passed by round table") {
        assert acquisition.passed = 1;
    }

    let (router_contract_address) = router_contract.read();
    let (lords_contract_address) = lords_contract.read();
    let (local eth_contract_address) = eth_contract.read();

    // swap tokens
    // TODO: make sure that giving low part of Uint256 only does not create issues
    swap_lords_for_exact_eth(
        router_contract_address,
        lords_contract_address,
        eth_contract_address,
        max_lords_amount,
        Uint256(acquisition.eth_amount, 0),
    );

    let (l1_empire_contract_address) = l1_empire_contract.read();
    let (token_bridge_contract_address) = token_bridge_contract.read();

    // bridge token eth to l1
    // TODO: make sure that giving low part of Uint256 only does not create issues
    ITokenBridge.initiate_withdraw(
        contract_address=token_bridge_contract_address,
        l1_recipient=l1_empire_contract_address,
        amount=Uint256(acquisition.eth_amount, 0),
    );

    // send message to l1 using the send_message_to_l1() function
    message_l1_acquire_realm(
        l1_empire_contract_address, acquisition.token_id, acquisition.eth_amount
    );

    // delete the proposition once message has been sent
    acquisition_candidate.write(proposing_realm_id, Acquisition(0, 0, 0));

    return ();
}
