%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin

from contracts.empires.constants import TAX_PRECISION

const EMPEROR = 123456;
const REALM_CONTRACT = 1234;

func __setup__() {
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
        address = deploy_contract("./contracts/empire.cairo", 
                    [ids.EMPEROR, ids.REALM_CONTRACT, producer_taxes, attacker_taxes, goblin_taxes]).contract_address
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
