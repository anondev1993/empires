%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.starknet.common.syscalls import get_contract_address
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.alloc import alloc

from contracts.empires.realms import harvest, claim_resources
from contracts.empires.helpers import get_resources, get_owners, get_resources_refund
from Realms.realms import (
    AMOUNT_FISH,
    AMOUNT_WHEAT,
    AMOUNT_WOOD,
    AMOUNT_STONE,
    AMOUNT_COAL,
    AMOUNT_COPPER,
    AMOUNT_OBSIDIAN,
    AMOUNT_SILVER,
    AMOUNT_IRONWOOD,
    AMOUNT_COLD_IRON,
    AMOUNT_GOLD,
    AMOUNT_HARTWOOD,
    AMOUNT_DIAMONDS,
    AMOUNT_SAPPHIRE,
    AMOUNT_RUBY,
    AMOUNT_DEEP_CRYSTAL,
    AMOUNT_IGNIUM,
    AMOUNT_ETHEREAL_SILICA,
    AMOUNT_TRUE_ICE,
    AMOUNT_TWILIGHT_QUARTZ,
    AMOUNT_ALCHEMICAL_SILVER,
    AMOUNT_ADAMANTINE,
    AMOUNT_MITHRAL,
    AMOUNT_DRAGONHIDE,
)
from contracts.settling_game.utils.game_structs import ResourceIds
from contracts.settling_game.interfaces.IERC1155 import IERC1155
from contracts.token.constants import IERC1155_RECEIVER_ID, IACCOUNT_ID

const URI = 123;
const ACCOUNT = 12345;
const EMPEROR = 12414;
const REALM_ID = 1;
const PROXY_ADMIN = 1234;

const FOOD_MODULE = 123;
const PRODUCER_TAXES = 30;

// Helper

@view
func supportsInterface{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    interfaceId: felt
) -> (success: felt) {
    if (interfaceId == IERC1155_RECEIVER_ID) {
        return (success=0);
    }
    return (success=1);
}

// Interface

@contract_interface
namespace IProxy {
    func initializer(uri: felt, proxy_admin: felt) {
    }
}

@external
func __setup__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    let (local address) = get_contract_address();
    %{
        context.self_address = ids.address 
        store(context.self_address, "Ownable_owner", [ids.EMPEROR])
    %}
    local erc1155_address;
    let (local ids: Uint256*) = alloc();
    let (local amounts: Uint256*) = alloc();
    let (data: felt*) = alloc();
    assert data[0] = 0;
    assert [ids] = Uint256(ResourceIds.fish, 0);
    assert [ids + Uint256.SIZE] = Uint256(ResourceIds.wheat, 0);
    assert [amounts] = Uint256(AMOUNT_FISH, 0);
    assert [amounts + Uint256.SIZE] = Uint256(AMOUNT_WHEAT, 0);
    %{
        context.erc1155_contract_address = deploy_contract('./lib/realms_contracts_git/contracts/token/ERC1155_Mintable_Burnable.cairo').contract_address
        context.realm_contract_address = deploy_contract('./tests/Realms/realms.cairo', [1, context.erc1155_contract_address, context.self_address]).contract_address
        context.account = deploy_contract('./lib/argent_contracts_starknet_git/contracts/account/ArgentAccount.cairo').contract_address
        ids.address = context.self_address
        ids.erc1155_address = context.erc1155_contract_address
        stop_prank = start_prank(ids.address, target_contract_address=context.erc1155_contract_address)

        store(context.self_address, "realms", [context.account, 1, 0, 0], key=[ids.REALM_ID])
        store(context.self_address, "producer_taxes", [ids.PRODUCER_TAXES])
        store(context.self_address, "food_module", [context.realm_contract_address])
        store(context.self_address, "resource_module", [context.realm_contract_address])
        store(context.self_address, "erc1155_contract", [ids.erc1155_address])
    %}
    IProxy.initializer(contract_address=erc1155_address, uri=URI, proxy_admin=address);
    IERC1155.mintBatch(
        contract_address=erc1155_address,
        to=address,
        ids_len=2,
        ids=ids,
        amounts_len=2,
        amounts=amounts,
        data_len=1,
        data=data,
    );
    return ();
}

@external
func test_resources_arr{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let (resources: Uint256*) = get_resources();
    %{
        for i in range(22):
            assert i+1 == memory[ids.resources._reference_value + 2*i]
            assert 0 == memory[ids.resources._reference_value + 2*i + 1]
    %}
    return ();
}

@external
func test_resources_refund{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    let (post_resources: Uint256*) = alloc();
    let (pre_resources: Uint256*) = alloc();
    let (local diff_resources: Uint256*) = alloc();
    let (resources) = get_resources();
    %{
        from random import randint
        refunds = []
        for i in range(22):
            pre = randint(1, 100000)
            add = randint(1, 100000)
            memory[ids.pre_resources._reference_value + 2*i] = pre
            memory[ids.pre_resources._reference_value + 2*i + 1] = 0
            memory[ids.post_resources._reference_value + 2*i] = pre + add
            memory[ids.post_resources._reference_value + 2*i + 1] = 0
            refunds.append(add * (100 - ids.PRODUCER_TAXES) // 100)
    %}
    get_resources_refund(
        len=22,
        post_resources=post_resources,
        pre_resources=pre_resources,
        diff_resources=diff_resources,
        tax=PRODUCER_TAXES,
    );
    %{
        for i in range(22):
            ref = memory[ids.diff_resources._reference_value + 2*i]
            assert ref == refunds[i], f'refund error, expected {diffs[i]}, got {ref}'
    %}
    return ();
}

@external
func test_owners_arr{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let (owners) = get_owners();
    let (empire) = get_contract_address();
    %{
        for i in range(22):
            assert ids.empire == memory[ids.owners + i]
    %}
    return ();
}

@external
func test_harvest_not_empire{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    %{
        start_prank(ids.ACCOUNT) 
        store(context.self_address, "Ownable_owner", [ids.ACCOUNT])
        expect_revert(error_message="realm not part of the empire")
    %}
    harvest(token_id=Uint256(1, 0), food_building_id=1);
    return ();
}

@external
func test_harvest{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;
    %{
        stop_prank = start_prank(ids.EMPEROR) 
        pre_fishes = load(context.erc1155_contract_address, "ERC1155_balances", "Uint256", key=[ids.ResourceIds.fish, 0, context.self_address])[0]
        pre_wheats = load(context.erc1155_contract_address, "ERC1155_balances", "Uint256", key=[ids.ResourceIds.wheat, 0, context.self_address])[0]
    %}
    harvest(token_id=Uint256(REALM_ID, 0), food_building_id=1);
    %{
        post_fishes_empire = load(context.erc1155_contract_address, "ERC1155_balances", "Uint256", key=[ids.ResourceIds.fish, 0, context.self_address])[0]
        post_wheat_empire = load(context.erc1155_contract_address, "ERC1155_balances", "Uint256", key=[ids.ResourceIds.wheat, 0, context.self_address])[0]
        post_fishes_account = load(context.erc1155_contract_address, "ERC1155_balances", "Uint256", key=[ids.ResourceIds.fish, 0, context.account])[0]
        post_wheat_account = load(context.erc1155_contract_address, "ERC1155_balances", "Uint256", key=[ids.ResourceIds.wheat, 0, context.account])[0]

        diff_fish = (100 - ids.PRODUCER_TAXES) * ids.AMOUNT_FISH // 100
        diff_wheat = (100 - ids.PRODUCER_TAXES) * ids.AMOUNT_WHEAT // 100
        assert post_fishes_empire == pre_fishes + ids.AMOUNT_FISH - diff_fish, f'post fishes empire error, expected {post_fishes_empire}, got {pre_fishes + ids.AMOUNT_FISH - diff_fish}'
        assert post_wheat_empire == pre_wheats + ids.AMOUNT_WHEAT - diff_wheat, f'post wheat empire error, expected {post_wheat_empire}, got {pre_wheats + ids.AMOUNT_WHEAT - diff_wheat}'
        assert post_fishes_account == diff_fish, f'post fishes account error, expected {post_fishes_account}, got {diff_fish}'
        assert post_wheat_account == diff_wheat, f'post wheat account error, expected {post_wheat_account}, got {diff_wheat}'
    %}
    return ();
}

@external
func test_claim_resources_not_empire{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    %{
        start_prank(ids.EMPEROR) 
        store(context.self_address, "Ownable_owner", [ids.EMPEROR])
        expect_revert(error_message="realm not part of the empire")
    %}
    claim_resources(token_id=Uint256(1, 0));
    return ();
}

@external
func test_claim_resources{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;
    %{
        stop_prank = start_prank(ids.EMPEROR) 
        resources_increment = [ids.AMOUNT_WOOD,
                    ids.AMOUNT_STONE,
                    ids.AMOUNT_COAL,
                    ids.AMOUNT_COPPER ,
                    ids.AMOUNT_OBSIDIAN ,
                    ids.AMOUNT_SILVER ,
                    ids.AMOUNT_IRONWOOD,
                    ids.AMOUNT_COLD_IRON,
                    ids.AMOUNT_GOLD,
                    ids.AMOUNT_HARTWOOD,
                    ids.AMOUNT_DIAMONDS,
                    ids.AMOUNT_SAPPHIRE,
                    ids.AMOUNT_RUBY,
                    ids.AMOUNT_DEEP_CRYSTAL,
                    ids.AMOUNT_IGNIUM,
                    ids.AMOUNT_ETHEREAL_SILICA,
                    ids.AMOUNT_TRUE_ICE,
                    ids.AMOUNT_TWILIGHT_QUARTZ,
                    ids.AMOUNT_ALCHEMICAL_SILVER,
                    ids.AMOUNT_ADAMANTINE,
                    ids.AMOUNT_MITHRAL,
                    ids.AMOUNT_DRAGONHIDE]
        pre_resources = []
        for i in range(22):
            pre_resources.append(load(context.erc1155_contract_address, "ERC1155_balances", "Uint256", key=[i+1, 0, context.self_address])[0])
    %}
    claim_resources(token_id=Uint256(REALM_ID, 0));
    %{
        for i in range(22):
            post_resource_empire = load(context.erc1155_contract_address, "ERC1155_balances", "Uint256", key=[i+1, 0, context.self_address])[0]
            post_resource_account = load(context.erc1155_contract_address, "ERC1155_balances", "Uint256", key=[i+1, 0, context.account])[0]
            diff = (100 - ids.PRODUCER_TAXES) * resources_increment[i] // 100
            assert post_resource_empire == pre_resources[i] + resources_increment[i] - diff, f'post resource empire {i} error, expected {pre_resources[i] + resources_increment[i] - diff}, got {post_resource_empire}'
            assert post_resource_account == diff, f'post resource account {i} error, expected {diff}, got {post_resource_account}'
    %}
    return ();
}
