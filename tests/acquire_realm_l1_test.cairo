%lang starknet

from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.starknet.common.syscalls import get_contract_address
from starkware.cairo.common.pow import pow
from starkware.cairo.common.alloc import alloc

from contracts.empires.internals import swap_lords_for_exact_eth

@contract_interface
namespace IMintableToken {
    func decimals() -> (decimals: felt) {
    }

    func permissionedMint(recipient: felt, amount: Uint256) {
    }

    func approve(spender: felt, amount: Uint256) -> (success: felt) {
    }
}

@contract_interface
namespace ITokenBridge {
    func initialize(init_vector_len: felt, init_vector: felt*) -> () {
    }
    func set_l2_token(l2_token_address: felt) -> () {
    }
    func set_l1_bridge(l1_bridge_address: felt) -> () {
    }
}

@contract_interface
namespace IEmpire {
    func acquire_realm_l1(max_lords_amount: Uint256, proposing_realm_id: felt) -> () {
    }
}

@contract_interface
namespace IERC20 {
    func decimals() -> (decimals: felt) {
    }

    func mint(recipient: felt, amount: Uint256) {
    }

    func approve(spender: felt, amount: Uint256) -> (success: felt) {
    }
}

@contract_interface
namespace IPair {
    func get_reserves() -> (reserve0: Uint256, reserve1: Uint256, block_timestamp_last: felt) {
    }
}

@contract_interface
namespace IRouter {
    func factory() -> (address: felt) {
    }

    func sort_tokens(tokenA: felt, tokenB: felt) -> (token0: felt, token1: felt) {
    }

    func add_liquidity(
        tokenA: felt,
        tokenB: felt,
        amountADesired: Uint256,
        amountBDesired: Uint256,
        amountAMin: Uint256,
        amountBMin: Uint256,
        to: felt,
        deadline: felt,
    ) -> (amountA: Uint256, amountB: Uint256, liquidity: Uint256) {
    }

    func remove_liquidity(
        tokenA: felt,
        tokenB: felt,
        liquidity: Uint256,
        amountAMin: Uint256,
        amountBMin: Uint256,
        to: felt,
        deadline: felt,
    ) -> (amountA: Uint256, amountB: Uint256) {
    }

    func swap_exact_tokens_for_tokens(
        amountIn: Uint256,
        amountOutMin: Uint256,
        path_len: felt,
        path: felt*,
        to: felt,
        deadline: felt,
    ) -> (amounts_len: felt, amounts: Uint256*) {
    }

    func swap_tokens_for_exact_tokens(
        amountOut: Uint256,
        amountInMax: Uint256,
        path_len: felt,
        path: felt*,
        to: felt,
        deadline: felt,
    ) -> (amounts_len: felt, amounts: Uint256*) {
    }
}

@contract_interface
namespace IFactory {
    func create_pair(token0: felt, token1: felt) -> (pair: felt) {
    }

    func get_pair(token0: felt, token1: felt) -> (pair: felt) {
    }

    func get_all_pairs() -> (all_pairs_len: felt, all_pairs: felt*) {
    }
}

@external
func __setup__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> () {
    alloc_locals;

    const DEPLOYER_ADDRESS = 1111;
    const USER_1_ADDRESS = 2222;
    const USER_2_ADDRESS = 3333;
    const EMPEROR = 4444;
    const REALM_CONTRACT = 6666;
    const BRIDGE_GOVERNOR = 7777;
    const L1_ADDRESS = 8888;
    const L1_TOKEN_BRIDGE_ADDRESS = 9999;

    // realms module contracts
    const BUILDING_MODULE_ADDRESS = 5551;
    const FOOD_MODULE_ADDRESS = 5552;
    const GOBLIN_TOWN_MODULE_ADDRESS = 5553;
    const RESOURCE_MODULE_ADDRESS = 5554;
    const TRAVEL_MODULE_ADDRESS = 5555;
    const COMBAT_MODULE_ADDRESS = 5556;

    local factory_address;
    local router_address;
    local token_0_address;
    local token_1_address;
    local token_bridge_address;

    %{
        ## TOKEN BRIDGE
        context.token_bridge_address = deploy_contract("tests/starkgate/token_bridge.cairo").contract_address
        ids.token_bridge_address = context.token_bridge_address
        context.BRIDGE_GOVERNOR = ids.BRIDGE_GOVERNOR
        context.L1_TOKEN_BRIDGE_ADDRESS = ids.L1_TOKEN_BRIDGE_ADDRESS
    %}

    %{
        ## ERC20 TOKENS
        context.DEPLOYER_ADDRESS = ids.DEPLOYER_ADDRESS
        context.USER_1_ADDRESS = ids.USER_1_ADDRESS
        context.USER_2_ADDRESS = ids.USER_2_ADDRESS
        context.token_0_address = deploy_contract("lib/cairo_contracts_git/src/openzeppelin/token/erc20/presets/ERC20Mintable.cairo", [11, 1, 18, 0, 0, context.DEPLOYER_ADDRESS, context.DEPLOYER_ADDRESS]).contract_address
        context.token_1_address = deploy_contract("tests/starkgate/ERC20Bridgeable.cairo", [22, 2, 18, context.token_bridge_address]).contract_address
        ids.token_0_address = context.token_0_address
        ids.token_1_address = context.token_1_address
    %}
    %{
        ## JEDISWAP
        context.declared_pair_class_hash = declare("lib/JediSwap_git/contracts/Pair.cairo").class_hash
        context.factory_address = deploy_contract("lib/JediSwap_git/contracts/Factory.cairo", [context.declared_pair_class_hash, context.DEPLOYER_ADDRESS]).contract_address
        context.router_address = deploy_contract("lib/JediSwap_git/contracts/Router.cairo", [context.factory_address]).contract_address
        ids.factory_address = context.factory_address
        ids.router_address = context.router_address
    %}
    %{
        ## EMPIRE
        context.empire_address = deploy_contract("./contracts/empire.cairo", 
                    [ids.EMPEROR,
                     ids.REALM_CONTRACT,
                     ids.BUILDING_MODULE_ADDRESS, 
                     ids.FOOD_MODULE_ADDRESS,
                     ids.GOBLIN_TOWN_MODULE_ADDRESS,
                     ids.RESOURCE_MODULE_ADDRESS,
                     ids.TRAVEL_MODULE_ADDRESS, 
                     ids.COMBAT_MODULE_ADDRESS,
                     context.token_0_address, 
                     context.token_1_address, 
                     context.router_address,
                     ids.L1_ADDRESS, 
                     context.token_bridge_address, 0, 0, 0]).contract_address
        context.EMPEROR = ids.EMPEROR
    %}

    let (init_vector: felt*) = alloc();
    assert [init_vector] = BRIDGE_GOVERNOR;

    // initialize the bridge
    ITokenBridge.initialize(
        contract_address=token_bridge_address, init_vector_len=1, init_vector=init_vector
    );

    let (sorted_token_0_address, sorted_token_1_address) = IRouter.sort_tokens(
        contract_address=router_address, tokenA=token_0_address, tokenB=token_1_address
    );

    let (pair_address) = IFactory.create_pair(
        contract_address=factory_address,
        token0=sorted_token_0_address,
        token1=sorted_token_1_address,
    );

    %{
        context.sorted_token_0_address = ids.sorted_token_0_address
        context.sorted_token_1_address = ids.sorted_token_1_address
        context.pair_address = ids.pair_address
    %}

    let (token_0_decimals) = IERC20.decimals(contract_address=sorted_token_0_address);
    let (token_0_multiplier) = pow(10, token_0_decimals);

    let (token_1_decimals) = IMintableToken.decimals(contract_address=sorted_token_1_address);
    let (token_1_multiplier) = pow(10, token_1_decimals);

    let amount_to_mint_token_0 = 100 * token_0_multiplier;
    %{ stop_prank = start_prank(context.DEPLOYER_ADDRESS, target_contract_address=ids.token_0_address) %}
    IERC20.mint(
        contract_address=token_0_address,
        recipient=USER_1_ADDRESS,
        amount=Uint256(amount_to_mint_token_0, 0),
    );
    IERC20.mint(
        contract_address=token_0_address,
        recipient=USER_2_ADDRESS,
        amount=Uint256(amount_to_mint_token_0, 0),
    );
    %{ stop_prank() %}

    let amount_to_mint_token_1 = 100 * token_1_multiplier;
    %{ stop_prank = start_prank(context.token_bridge_address, target_contract_address=ids.token_1_address) %}
    IMintableToken.permissionedMint(
        contract_address=token_1_address,
        recipient=USER_1_ADDRESS,
        amount=Uint256(amount_to_mint_token_1, 0),
    );
    IMintableToken.permissionedMint(
        contract_address=token_1_address,
        recipient=USER_2_ADDRESS,
        amount=Uint256(amount_to_mint_token_1, 0),
    );
    %{ stop_prank() %}

    // ## Add liquidity for first time
    let amount_token_0 = 20 * token_0_multiplier;
    %{ stop_prank = start_prank(ids.USER_1_ADDRESS, target_contract_address=ids.sorted_token_0_address) %}
    IERC20.approve(
        contract_address=sorted_token_0_address,
        spender=router_address,
        amount=Uint256(amount_token_0, 0),
    );
    %{ stop_prank() %}

    let amount_token_1 = 40 * token_1_multiplier;
    %{ stop_prank = start_prank(ids.USER_1_ADDRESS, target_contract_address=ids.sorted_token_1_address) %}
    IMintableToken.approve(
        contract_address=sorted_token_1_address,
        spender=router_address,
        amount=Uint256(amount_token_1, 0),
    );
    %{ stop_prank() %}

    %{ stop_prank = start_prank(ids.USER_1_ADDRESS, target_contract_address=ids.router_address) %}
    let (amountA: Uint256, amountB: Uint256, liquidity: Uint256) = IRouter.add_liquidity(
        contract_address=router_address,
        tokenA=sorted_token_0_address,
        tokenB=sorted_token_1_address,
        amountADesired=Uint256(amount_token_0, 0),
        amountBDesired=Uint256(amount_token_1, 0),
        amountAMin=Uint256(1, 0),
        amountBMin=Uint256(1, 0),
        to=USER_1_ADDRESS,
        deadline=0,
    );
    %{ stop_prank() %}

    return ();
}

@external
func test_acquire_realm_l1{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    ) {
    alloc_locals;

    const PROPOSING_REALM_ID = 0001;
    const TOKEN_ID = 0002;

    local token_0_address;
    local token_1_address;
    local router_address;
    local USER_2_ADDRESS;
    local empire_address;
    local token_bridge_address;
    local l1_token_bridge_address;

    %{
        ids.token_0_address = context.token_0_address
        ids.token_1_address = context.token_1_address
        ids.router_address = context.router_address
        ids.USER_2_ADDRESS = context.USER_2_ADDRESS
        ids.empire_address = context.empire_address
        ids.token_bridge_address = context.token_bridge_address
        ids.l1_token_bridge_address = context.L1_TOKEN_BRIDGE_ADDRESS
    %}

    // fill empire treasurey with 100 token 0 (lords)
    let (token_0_decimals) = IERC20.decimals(contract_address=token_0_address);
    let (token_0_multiplier) = pow(10, token_0_decimals);
    let amount_to_mint_token_0 = 100 * token_0_multiplier;

    %{ stop_prank = start_prank(context.DEPLOYER_ADDRESS, target_contract_address=ids.token_0_address) %}
    IERC20.mint(
        contract_address=token_0_address,
        recipient=empire_address,
        amount=Uint256(amount_to_mint_token_0, 0),
    );
    %{ stop_prank() %}

    // amount of token 1 (eth) that we want from swap
    let (token_1_decimals) = IMintableToken.decimals(contract_address=token_1_address);
    let (token_1_multiplier) = pow(10, token_1_decimals);
    local amount_token_1 = 2 * token_1_multiplier;

    %{ stop_prank = start_prank(context.BRIDGE_GOVERNOR, target_contract_address=context.token_bridge_address) %}
    ITokenBridge.set_l2_token(
        contract_address=token_bridge_address, l2_token_address=token_1_address
    );
    ITokenBridge.set_l1_bridge(
        contract_address=token_bridge_address, l1_bridge_address=l1_token_bridge_address
    );
    %{ stop_prank() %}

    // store an proposal to acquire realm l1 that was passed by the round_table
    %{ store(context.empire_address, "acquisition_candidate", [ids.TOKEN_ID, ids.amount_token_1, 1], key=[ids.PROPOSING_REALM_ID]) %}

    %{ stop_prank = start_prank(context.EMPEROR, target_contract_address=context.empire_address) %}

    IEmpire.acquire_realm_l1(
        contract_address=empire_address,
        max_lords_amount=Uint256(10 ** 30, 0),
        proposing_realm_id=PROPOSING_REALM_ID,
    );

    %{ stop_prank() %}

    return ();
}
